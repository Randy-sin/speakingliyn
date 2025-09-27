//
//  StreamingASRService.swift
//  speaking
//
//  Created by Randy on 25/9/2025.
//

import Foundation
@preconcurrency import AVFoundation

protocol StreamingASRServiceProtocol: AnyObject {
    func startStreaming() async throws
    func stopStreaming() async throws
    
    var onPartialResult: ((String) -> Void)? { get set }
    var onFinalResult: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
}

// MARK: - 基于VAD断句的流式ASR服务
@MainActor
final class StreamingASRService: NSObject, StreamingASRServiceProtocol {
    
    // 回调
    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    // 核心服务
    private let asrService: QwenASRServiceProtocol
    private let fileUploadService: FileUploadServiceProtocol
    
    // 音频引擎
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioRecorder: AVAudioRecorder?
    
    // VAD参数（严格检测版）
    private var dynamicSilenceThreshold: Float = 0.008  // 动态静音阈值，参考官方推荐
    private let silenceDuration: TimeInterval = 1.0     // 缩短为1秒，更快响应
    private let minSpeechDuration: TimeInterval = 0.3   // 最短0.3秒，避免误触
    private let thresholdAdaptationRate: Float = 0.1    // 阈值自适应速率
    
    // 状态跟踪
    private var isStreaming = false
    private var speechStartTime: Date?
    private var lastSpeechTime: Date?
    private var silenceStartTime: Date?  // 新增：静音开始时间
    private var currentRecordingURL: URL?
    private var vadCheckTimer: Timer?  // 新增：定期检查VAD状态的Timer
    
    // 音量监控
    private var audioLevel: Float = 0.0
    private let smoothingFactor: Float = 0.2
    private var recentAudioLevels: [Float] = [] // 用于更准确的静音检测
    private var backgroundNoiseLevel: Float = 0.0 // 背景噪音水平
    private var speechPeakLevel: Float = 0.0      // 语音峰值水平
    private var consecutiveSilenceCount: Int = 0   // 连续静音检测次数
    
    init(asrService: QwenASRServiceProtocol = QwenASRService(), fileUploadService: FileUploadServiceProtocol = FileUploadService()) {
        self.asrService = asrService
        self.fileUploadService = fileUploadService
        super.init()
    }
    
    func startStreaming() async throws {
        guard !isStreaming else { return }
        
        print("[StreamASR] 开始VAD语音识别（优化版）")
        
        // 请求麦克风权限 (简化处理，避免iOS版本兼容问题)
        let session = AVAudioSession.sharedInstance()
        if session.recordPermission != .granted {
            print("[StreamASR] 请求麦克风权限...")
            let granted = await withCheckedContinuation { continuation in
                session.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            if !granted {
                throw NSError(domain: "StreamingASRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "需要麦克风权限"])
            }
        }
        
        try await setupAudioSession()
        try await setupAudioEngine()
        try await startRecording()
        
        isStreaming = true
        speechStartTime = nil
        lastSpeechTime = nil
        silenceStartTime = nil
        audioLevel = 0.0
        recentAudioLevels = []
        backgroundNoiseLevel = 0.0
        speechPeakLevel = 0.0
        consecutiveSilenceCount = 0
        dynamicSilenceThreshold = 0.015  // 提高初始阈值
        
        // 启动定期VAD检查
        vadCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task {
                await self?.checkVADStatus()
            }
        }
        
        print("[StreamASR] VAD语音识别已启动，等待语音...")
    }
    
    func stopStreaming() async throws {
        guard isStreaming else { return }
        
        isStreaming = false
        
        // 停止音频引擎
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        inputNode = nil
        
        // 停止录音
        audioRecorder?.stop()
        audioRecorder = nil
        
        // 取消定时器
        vadCheckTimer?.invalidate()
        vadCheckTimer = nil
        
        // 处理最终结果
        if let recordingURL = currentRecordingURL {
            await processRecording(url: recordingURL, isFinal: true)
        }
        
        print("[StreamASR] VAD语音识别已停止")
    }
    
    // MARK: - 音频设置
    
    private func setupAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)
        print("[StreamASR] 音频会话配置成功")
    }
    
    private func setupAudioEngine() async throws {
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            throw NSError(domain: "StreamingASRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建音频引擎"])
        }
        
        inputNode = audioEngine.inputNode
        let inputFormat = inputNode?.outputFormat(forBus: 0)
        
        // 安装音频监听tap（用于VAD检测）
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            Task {
                await self?.processAudioBuffer(buffer)
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        print("[StreamASR] 音频引擎启动成功")
    }
    
    private func startRecording() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("vad_stream_\(UUID().uuidString).m4a")
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
        audioRecorder?.record()
        currentRecordingURL = tempURL
        
        print("[StreamASR] 开始录音到文件: \(tempURL.lastPathComponent)")
    }
    
    // MARK: - VAD音频处理（简化版）
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard isStreaming else { return }
        
        // 计算当前音频级别
        let currentLevel = calculateAudioLevel(buffer)
        
        // 应用平滑滤波
        audioLevel = audioLevel * (1 - smoothingFactor) + currentLevel * smoothingFactor
        
        // 保存最近的音频级别用于更准确的判断
        recentAudioLevels.append(audioLevel)
        if recentAudioLevels.count > 10 {
            recentAudioLevels.removeFirst()
        }
    }
    
    private func checkVADStatus() async {
        guard isStreaming else { return }
        
        let now = Date()
        let avgLevel = recentAudioLevels.isEmpty ? 0.0 : recentAudioLevels.reduce(0, +) / Float(recentAudioLevels.count)
        
        // 动态学习背景噪音水平（在没有语音时持续学习）
        if speechStartTime == nil {
            if backgroundNoiseLevel == 0.0 {
                backgroundNoiseLevel = avgLevel
                dynamicSilenceThreshold = max(backgroundNoiseLevel * 3.0, 0.015) // 提高到3倍，最小阈值0.015
                print("[StreamASR] 📊 学习背景噪音: \(String(format: "%.4f", backgroundNoiseLevel)), 动态阈值: \(String(format: "%.4f", dynamicSilenceThreshold))")
            } else {
                // 持续更新背景噪音水平
                backgroundNoiseLevel = backgroundNoiseLevel * 0.98 + avgLevel * 0.02
                dynamicSilenceThreshold = max(backgroundNoiseLevel * 3.0, 0.015) // 提高倍数和最小阈值
            }
        }
        
        // 计算音量变化率（检测是否有语音活动）
        let volumeVariation = recentAudioLevels.count > 1 ? 
            abs(recentAudioLevels.last! - recentAudioLevels[recentAudioLevels.count-2]) : 0.0
        
        // 计算最近几帧的平均变化率（更准确的活动检测）
        let recentVariations = recentAudioLevels.count >= 3 ? 
            (0..<min(recentAudioLevels.count-1, 3)).map { i in
                abs(recentAudioLevels[recentAudioLevels.count-1-i] - recentAudioLevels[recentAudioLevels.count-2-i])
            } : [volumeVariation]
        let avgVariation = recentVariations.reduce(0, +) / Float(recentVariations.count)
        
        // 更严格的语音检测：需要明显的音量变化才算语音
        let isLoudEnough = avgLevel > dynamicSilenceThreshold
        let hasSignificantVariation = avgVariation > 0.008  // 提高变化率阈值
        
        // 语音结束检测：如果当前音量比峰值下降很多，也认为可能是语音结束
        let peakDropDetection = speechPeakLevel > 0.02 && (avgLevel < speechPeakLevel * 0.4)
        
        let isSpeaking = isLoudEnough && hasSignificantVariation && !peakDropDetection
        
        // 更新语音峰值水平
        if isSpeaking && avgLevel > speechPeakLevel {
            speechPeakLevel = avgLevel
        }
        
        print("[StreamASR] 🔊 音量: \(String(format: "%.4f", avgLevel)), 阈值: \(String(format: "%.4f", dynamicSilenceThreshold)), 变化: \(String(format: "%.4f", avgVariation)), 峰值: \(String(format: "%.4f", speechPeakLevel)), 说话: \(isSpeaking)")
        
        if isSpeaking {
            // 检测到语音活动
            consecutiveSilenceCount = 0
            
            if speechStartTime == nil {
                speechStartTime = now
                print("[StreamASR] 🎤 检测到语音开始! (峰值: \(String(format: "%.4f", speechPeakLevel)))")
            }
            lastSpeechTime = now
            silenceStartTime = nil  // 重置静音开始时间
            
        } else {
            // 可能是静音
            consecutiveSilenceCount += 1
            
            // 需要连续多次检测到静音才确认（减少误判）
            if let speechStart = speechStartTime, consecutiveSilenceCount >= 3 {
                if silenceStartTime == nil {
                    silenceStartTime = now
                    print("[StreamASR] 🔇 确认静音开始... (连续静音检测: \(consecutiveSilenceCount)次)")
                }
                
                let currentSilenceDuration = now.timeIntervalSince(silenceStartTime!)
                print("[StreamASR] ⏰ 静音时长: \(String(format: "%.1f", currentSilenceDuration))s / \(silenceDuration)s")
                
                // 检查是否达到静音阈值
                if currentSilenceDuration >= silenceDuration {
                    let speechDuration = (lastSpeechTime ?? now).timeIntervalSince(speechStart)
                    
                    if speechDuration >= minSpeechDuration {
                        print("[StreamASR] ✅ 达到静音阈值，自动结束识别！语音时长: \(String(format: "%.1f", speechDuration))s, 峰值: \(String(format: "%.4f", speechPeakLevel))")
                        await handleAutoEnd()
                    } else {
                        print("[StreamASR] ⏱️ 语音太短(\(String(format: "%.1f", speechDuration))s)，继续等待...")
                        // 重置状态继续等待
                        speechStartTime = nil
                        lastSpeechTime = nil
                        silenceStartTime = nil
                        consecutiveSilenceCount = 0
                        speechPeakLevel = 0.0
                    }
                }
            }
        }
    }
    
    private func handleAutoEnd() async {
        print("[StreamASR] 🎯 自动断句触发！")
        
        // 立即触发界面关闭回调
        onPartialResult?("检测到断句，正在识别...")
        
        // 在后台处理ASR识别
        Task {
            await self.processRecordingInBackground()
        }
        
        // 立即停止录音状态
        try? await stopStreaming()
    }
    
    private func processRecordingInBackground() async {
        guard let recordingURL = currentRecordingURL else { return }
        
        print("[StreamASR] 🔄 后台处理录音识别...")
        
        do {
            // 检查文件大小
            let fileSize = try FileManager.default.attributesOfItem(atPath: recordingURL.path)[.size] as? Int ?? 0
            print("[StreamASR] 录音文件大小: \(fileSize) bytes")
            
            if fileSize < 1000 {
                print("[StreamASR] 录音文件太小，取消识别")
                onError?(NSError(domain: "StreamingASRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "录音文件太小"]))
                return
            }
            
            // 后台调用ASR服务识别
            let text = try await asrService.transcribe(audioURL: recordingURL, language: "zh")
            
            if !text.isEmpty {
                print("[StreamASR] ✅ 后台识别完成: \(text)")
                onFinalResult?(text)
            } else {
                print("[StreamASR] ❌ 后台识别结果为空")
                onError?(NSError(domain: "StreamingASRService", code: -2, userInfo: [NSLocalizedDescriptionKey: "没有识别到语音内容"]))
            }
            
            // 清理临时文件
            try? FileManager.default.removeItem(at: recordingURL)
            
        } catch {
            print("[StreamASR][Error] 后台识别失败: \(error)")
            onError?(error)
        }
    }
    
    private func calculateAudioLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData?[0] else { return 0.0 }
        
        var sum: Float = 0.0
        let frameLength = Int(buffer.frameLength)
        
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        
        return frameLength > 0 ? sum / Float(frameLength) : 0.0
    }
    
    private func processRecording(url: URL, isFinal: Bool) async {
        // 这个方法现在主要用于手动停止的情况
        if isFinal {
            await processRecordingInBackground()
        }
    }
}
