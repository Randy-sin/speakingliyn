//
//  AudioRecorderService.swift
//  speaking
//
//  Created by Randy on 25/9/2025.
//

import Foundation
import AVFoundation

protocol AudioRecorderServiceProtocol {
    func startRecording() async throws -> URL
    func stopRecording() async throws -> URL
    func cancelRecording() async
    var currentRecordingURL: URL? { get }
}

final class AudioRecorderService: NSObject, AudioRecorderServiceProtocol {
    private var audioRecorder: AVAudioRecorder?
    private(set) var currentRecordingURL: URL?
    private var isSessionConfigured = false
    
    override init() {
        super.init()
        // 预配置音频会话，减少录音启动延迟
        Task {
            await configureAudioSession()
        }
    }
    
    @MainActor
    private func configureAudioSession() {
        guard !isSessionConfigured else { return }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
            isSessionConfigured = true
            print("[Audio] Session pre-configured successfully")
        } catch {
            print("[Audio] Failed to pre-configure session: \(error)")
        }
    }
    
    func startRecording() async throws -> URL {
        // 确保音频会话已配置
        if !isSessionConfigured {
            await configureAudioSession()
        }
        
        // 生成临时文件URL
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("voice_\(UUID().uuidString).m4a")
        
        // 优化的录音设置
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue // 使用medium减少初始化时间
        ]
        
        // 快速初始化并开始录音
        audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
        audioRecorder?.record()
        currentRecordingURL = tempURL
        
        print("[Audio] Recording started immediately")
        return tempURL
    }
    
    func stopRecording() async throws -> URL {
        guard let recorder = audioRecorder, let url = currentRecordingURL else {
            throw NSError(domain: "AudioRecorderService", code: -1, userInfo: [NSLocalizedDescriptionKey: "录音未开始"])
        }
        
        recorder.stop()
        audioRecorder = nil
        let finalURL = url
        currentRecordingURL = nil
        
        return finalURL
    }
    
    func cancelRecording() async {
        audioRecorder?.stop()
        if let url = currentRecordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        audioRecorder = nil
        currentRecordingURL = nil
    }
}
