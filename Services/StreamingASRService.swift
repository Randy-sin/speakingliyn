//
//  StreamingASRService.swift
//  speaking
//
//  Created by Randy on 25/9/2025.
//

import Foundation
import AVFoundation

protocol StreamingASRServiceProtocol: AnyObject {
    func startStreaming() async throws
    func stopStreaming() async throws
    
    var onPartialResult: ((String) -> Void)? { get set }
    var onFinalResult: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
}

// MARK: - 基于VAD断句的流式ASR服务
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
    
    // VAD参数
    private let silenceThreshold: Float = 0.01    // 静音阈值
    private let silenceDuration: TimeInterval = 2.5  // 2.5秒静音判定句子结束
    private let minSpeechDuration: TimeInterval = 0.5  // 最短0.5秒才开始识别
    
    // 状态跟踪
    private var isStreaming = false
    private var speechStartTime: Date?
    private var lastSpeechTime: Date?
    private var silenceTimer: Timer?
    private var currentRecordingURL: URL?
    
    // 音量监控
    private var audioLevel: Float = 0.0
    private let smoothingFactor: Float = 0.3
    
    init(asrService: QwenASRServiceProtocol = QwenASRService(), fileUploadService: FileUploadServiceProtocol = FileUploadService()) {
        self.asrService = asrService
        self.fileUploadService = fileUploadService
        super.init()
    }
    
    func startStreaming() async throws {
        guard !isStreaming else { return }
        
        print("[StreamASR] 开始VAD语音识别（无时间限制，静音断句）")
        
        // 请求麦克风权限
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        if permissionStatus != .granted {
            print("[StreamASR] 请求麦克风权限...")
            let granted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
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
        
        // 取消静音计时器
        await MainActor.run {
            silenceTimer?.invalidate()
            silenceTimer = nil
        }
        
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
    
    // MARK: - VAD音频处理
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard isStreaming else { return }
        
        // 计算当前音频级别
        let currentLevel = calculateAudioLevel(buffer)
        
        // 应用平滑滤波减少噪声影响
        audioLevel = audioLevel * (1 - smoothingFactor) + currentLevel * smoothingFactor
        
        let isSpeaking = audioLevel > silenceThreshold
        let now = Date()
        
        if isSpeaking {
            // 检测到语音
            if speechStartTime == nil {
                speechStartTime = now
                print("[StreamASR] 🎤 检测到语音开始 (音量: \(String(format: "%.3f", audioLevel)))")
            }
            lastSpeechTime = now
            
            // 取消静音计时器
            await MainActor.run {
                self.silenceTimer?.invalidate()
                self.silenceTimer = nil
            }
            
        } else {
            // 检测到静音
            if let lastSpeech = lastSpeechTime {
                let currentSilenceDuration = now.timeIntervalSince(lastSpeech)
                
                // 如果静音超过阈值，开始倒计时结束识别
                if currentSilenceDuration >= silenceDuration {
                    await handleSilenceTimeout()
                } else if speechStartTime != nil && silenceTimer == nil {
                    // 开始静音计时器
                    await MainActor.run {
                        self.silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDuration, repeats: false) { [weak self] _ in
                            Task {
                                await self?.handleSilenceTimeout()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func handleSilenceTimeout() async {
        guard let speechStart = speechStartTime else { return }
        
        let speechDuration = Date().timeIntervalSince(speechStart)
        
        // 检查是否满足最短语音时长
        if speechDuration >= minSpeechDuration {
            print("[StreamASR] 🔇 检测到\(String(format: "%.1f", silenceDuration))秒静音，语音时长\(String(format: "%.1f", speechDuration))秒，自动结束识别")
            try? await stopStreaming()
        } else {
            print("[StreamASR] ⏱️ 语音时长太短(\(String(format: "%.1f", speechDuration))s < \(minSpeechDuration)s)，继续等待")
            // 重置状态继续等待
            speechStartTime = nil
            lastSpeechTime = nil
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
        do {
            print("[StreamASR] 开始处理录音文件...")
            
            // 检查文件大小
            let fileSize = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int ?? 0
            print("[StreamASR] 录音文件大小: \(fileSize) bytes")
            
            if fileSize < 1000 {
                print("[StreamASR] 录音文件太小，可能没有录制到有效音频")
                await MainActor.run {
                    self.onError?(NSError(domain: "StreamingASRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "录音文件太小"]))
                }
                return
            }
            
            // 调用ASR服务识别
            let text = try await asrService.transcribe(audioURL: url, language: "zh")
            
            if !text.isEmpty {
                print("[StreamASR] ✅ 识别结果: \(text)")
                if isFinal {
                    await MainActor.run {
                        self.onFinalResult?(text)
                    }
                } else {
                    await MainActor.run {
                        self.onPartialResult?(text)
                    }
                }
            } else {
                print("[StreamASR] ❌ 识别结果为空")
                if isFinal {
                    await MainActor.run {
                        self.onError?(NSError(domain: "StreamingASRService", code: -2, userInfo: [NSLocalizedDescriptionKey: "没有识别到语音内容"]))
                    }
                }
            }
            
            // 清理临时文件
            try? FileManager.default.removeItem(at: url)
            
        } catch {
            print("[StreamASR][Error] 处理录音失败: \(error)")
            await MainActor.run {
                self.onError?(error)
            }
        }
    }
}
