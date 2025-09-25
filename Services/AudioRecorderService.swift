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
    func cancelRecording()
}

final class AudioRecorderService: NSObject, AudioRecorderServiceProtocol {
    private var audioRecorder: AVAudioRecorder?
    private var currentURL: URL?
    
    func startRecording() async throws -> URL {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("voice_\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        audioRecorder = try AVAudioRecorder(url: tempURL, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        currentURL = tempURL
        return tempURL
    }
    
    func stopRecording() async throws -> URL {
        guard let recorder = audioRecorder, let url = currentURL else {
            throw NSError(domain: "AudioRecorderService", code: -1, userInfo: [NSLocalizedDescriptionKey: "录音未开始"])
        }
        recorder.stop()
        audioRecorder = nil
        return url
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        if let url = currentURL {
            try? FileManager.default.removeItem(at: url)
        }
        audioRecorder = nil
        currentURL = nil
    }
}
