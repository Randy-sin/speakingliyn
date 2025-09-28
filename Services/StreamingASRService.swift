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

// MARK: - 按照Fun-ASR文档优化的语音识别
final class StreamingASRService: NSObject, StreamingASRServiceProtocol, @unchecked Sendable {
    
    // 回调
    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    // 服务依赖
    private let asrService: QwenASRServiceProtocol
    private let fileUploadService: FileUploadServiceProtocol
    
    // 录音组件
    private var audioRecorder: AVAudioRecorder?
    private var audioEngine: AVAudioEngine?
    private var currentRecordingURL: URL?
    
    // Fun-ASR建议的参数
    private let silenceThreshold: Float = 0.01
    private let maxSentenceSilence: TimeInterval = 1.3  // Fun-ASR默认1300ms
    private let maxRecordingTime: TimeInterval = 10.0
    private let targetSampleRate: Double = 16000  // Fun-ASR支持16kHz
    
    // 状态
    private var isRecording = false
    private var lastSpeechTime: Date?
    private var audioLevel: Float = 0.0
    private var silenceTimer: Timer?
    private var maxTimeTimer: Timer?
    
    init(asrService: QwenASRServiceProtocol, fileUploadService: FileUploadServiceProtocol) {
        self.asrService = asrService
        self.fileUploadService = fileUploadService
        super.init()
    }
    
    // MARK: - 公开接口
    
    func startStreaming() async throws {
        guard !isRecording else { return }
        
        print("[ASR] 🎤 开始语音识别（Fun-ASR优化版）")
        
        try await setupAudioSession()
        try await startRecording()
        try await startAudioMonitoring()
        
        isRecording = true
        lastSpeechTime = nil
        
        // 设置最大录音时间保护
        await MainActor.run { [weak self] in
            self?.maxTimeTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingTime, repeats: false) { _ in
                Task { [weak self] in await self?.handleMaxTimeReached() }
            }
        }
        
        print("[ASR] ✅ 开始录音（16kHz采样，VAD断句1.3秒）")
    }
    
    func stopStreaming() async throws {
        guard isRecording else { return }
        
        isRecording = false
        
        // 清理定时器
        await MainActor.run {
            silenceTimer?.invalidate()
            silenceTimer = nil
            maxTimeTimer?.invalidate()
            maxTimeTimer = nil
        }
        
        // 停止录音和监听
        audioRecorder?.stop()
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        // 处理录音结果
        await processRecordingResult()
        
        // 清理
        audioRecorder = nil
        audioEngine = nil
        
        print("[ASR] 🛑 录音已停止")
    }
    
    // MARK: - 内部实现
    
    private func setupAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)
        
        // 按照Fun-ASR建议设置16kHz采样率
        try session.setPreferredSampleRate(targetSampleRate)
    }
    
    private func startRecording() async throws {
        let fileName = "voice_\(UUID().uuidString).m4a"
        currentRecordingURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        // Fun-ASR建议的音频格式设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: Int(targetSampleRate),  // 16kHz
            AVNumberOfChannelsKey: 1,  // 单声道
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        guard let url = currentRecordingURL else {
            throw NSError(domain: "ASR", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法创建录音文件"])
        }
        
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.record()
        
        print("[ASR] 📝 录音文件: \(fileName)")
    }
    
    private func startAudioMonitoring() async throws {
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }
        
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        // 监听音频数据，实现VAD
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            Task { await self?.processAudioBuffer(buffer) }
        }
        
        engine.prepare()
        try engine.start()
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) async {
        guard isRecording else { return }
        
        // 计算音量（VAD）
        let currentLevel = calculateAudioLevel(buffer)
        audioLevel = currentLevel
        
        let now = Date()
        let isSpeaking = audioLevel > silenceThreshold
        
        if isSpeaking {
            // 检测到声音
            lastSpeechTime = now
            
            // 显示正在识别状态
            onPartialResult?("正在识别...")
            
            // 取消静音计时器
            await MainActor.run {
                silenceTimer?.invalidate()
                silenceTimer = nil
            }
            
        } else if let lastSpeech = lastSpeechTime {
            // 检测静音 - 使用Fun-ASR建议的1.3秒
            let silenceTime = now.timeIntervalSince(lastSpeech)
            
            if silenceTime >= maxSentenceSilence && silenceTimer == nil {
                await MainActor.run { [weak self] in
                    self?.silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { _ in
                        Task { [weak self] in await self?.handleSilenceDetected() }
                    }
                }
            }
        }
    }
    
    private func handleSilenceDetected() async {
        print("[ASR] 🔇 检测到\(maxSentenceSilence)秒静音，停止录音")
        try? await stopStreaming()
    }
    
    private func handleMaxTimeReached() async {
        print("[ASR] ⏰ 达到最大录音时间，停止录音")
        try? await stopStreaming()
    }
    
    private func processRecordingResult() async {
        guard let recordingURL = currentRecordingURL else { return }
        
        do {
            // 检查文件
            let fileSize = try FileManager.default.attributesOfItem(atPath: recordingURL.path)[.size] as? Int ?? 0
            print("[ASR] 📊 录音文件大小: \(fileSize) bytes")
            
            guard fileSize > 8000 else {
                print("[ASR] ⚠️ 录音文件太小，可能没有说话")
                return
            }
            
            // 调用ASR识别 - 使用中文语言参数
            print("[ASR] 🎯 开始识别...")
            let text = try await asrService.transcribe(audioURL: recordingURL, language: "zh")
            
            if !text.isEmpty {
                print("[ASR] ✅ 识别结果: \(text)")
                await MainActor.run {
                    // 直接作为最终结果，不再检测标点符号
                    onFinalResult?(text)
                }
            } else {
                print("[ASR] ❌ 识别结果为空")
            }
            
        } catch {
            print("[ASR] ❌ 识别失败: \(error)")
            // 静默处理错误，不打扰用户
        }
        
        // 清理文件
        try? FileManager.default.removeItem(at: recordingURL)
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
}
