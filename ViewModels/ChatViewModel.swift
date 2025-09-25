//
//  ChatViewModel.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import Foundation
import SwiftUI
import Combine
import AVFoundation

@MainActor
class ChatViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var messages: [Message] = []
    @Published var inputText = ""
    @Published var isRecording = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var keyboardHeight: CGFloat = 0
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private let aiService: AIServiceProtocol
    private let audioPlayerService: AudioServiceProtocol
    private let asrService: QwenASRServiceProtocol
    private let recorderService: AudioRecorderServiceProtocol
    private var currentRecordingURL: URL?
    
    // MARK: - Init
    init(
        aiService: AIServiceProtocol = QwenChatService(),
        audioPlayerService: AudioServiceProtocol = AudioService(),
        asrService: QwenASRServiceProtocol = QwenASRService(),
        recorderService: AudioRecorderServiceProtocol = AudioRecorderService()
    ) {
        self.aiService = aiService
        self.audioPlayerService = audioPlayerService
        self.asrService = asrService
        self.recorderService = recorderService
        setupInitialMessage()
        setupKeyboardObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = Message(text: inputText, isFromUser: true)
        messages.append(userMessage)
        inputText = ""
        processConversation()
    }
    
    func startRecording() {
        guard !isRecording else { return }
        print("[Voice] startRecording tapped")
        Task {
            do {
                let url = try await recorderService.startRecording()
                await MainActor.run {
                    self.currentRecordingURL = url
                    self.isRecording = true
                    print("[Voice] recording started, file: \(url.path)")
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "录音失败：\(error.localizedDescription)"
                }
                print("[Voice][Error] startRecording failed: \(error)")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else {
            print("[Voice] stopRecording ignored, isRecording = false")
            return
        }
        print("[Voice] stopRecording tapped")
        Task {
            do {
                let url = try await recorderService.stopRecording()
                print("[Voice] recording stopped, url: \(url.path)")
                let transcription = try await asrService.transcribe(audioURL: url, language: nil)
                print("[Voice] ASR result: \(transcription)")
                await MainActor.run {
                    self.isRecording = false
                    self.currentRecordingURL = nil
                    if !transcription.isEmpty {
                        let userMessage = Message(text: transcription, isFromUser: true, audioURL: url)
                        self.messages.append(userMessage)
                        self.processConversation()
                    }
                }
            } catch {
                await MainActor.run {
                    self.isRecording = false
                    self.errorMessage = "录音处理失败：\(error.localizedDescription)"
                }
                print("[Voice][Error] stopRecording failed: \(error)")
            }
        }
    }
    
    func cancelRecording() {
        print("[Voice] cancelRecording")
        recorderService.cancelRecording()
        currentRecordingURL = nil
        isRecording = false
    }
    
    func clearChat() {
        messages = []
        setupInitialMessage()
    }
    
    func shareChat() {
        let chatText = messages.map { message in
            let sender = message.isFromUser ? "用户" : "AI"
            return "\(sender): \(message.text)"
        }.joined(separator: "\n")
        
        let activityViewController = UIActivityViewController(activityItems: [chatText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityViewController, animated: true)
        }
    }
    
    func playAudio(url: URL) {
        Task {
            try await audioPlayerService.playAudio(url)
        }
    }
    
    // MARK: - Private Methods
    private func setupInitialMessage() {
        let welcomeMessage = Message(
            text: "Hey! Welcome to your personal language dojo! 🎯 I'm LiY, your dedicated practice partner. Before we start, tell me: which language would you like to practice today? What's your approximate level (e.g., A1 beginner, B2 intermediate)? Any specific topics you're keen to chat about, like food, travel, or the latest movies? Don't be shy, let me know! 😊",
            isFromUser: false
        )
        messages = [welcomeMessage]
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] notification in
                if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                    self?.keyboardHeight = keyboardSize.cgRectValue.height
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                self?.keyboardHeight = 0
            }
            .store(in: &cancellables)
    }
    
    private func processConversation() {
        isLoading = true
        Task {
            do {
                let aiResponse = try await aiService.generateResponse(messages: messages)
                let aiMessage = Message(text: aiResponse.text, isFromUser: false, audioURL: aiResponse.audioURL)
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.messages.append(aiMessage)
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = Message(
                        text: "抱歉，我现在无法回复。请稍后再试。",
                        isFromUser: false
                    )
                    self.messages.append(errorMessage)
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                print("[Voice][Error] processConversation failed: \(error)")
            }
        }
    }
}

// MARK: - Protocols
protocol AIServiceProtocol {
    func generateResponse(messages: [Message]) async throws -> AIResponse
}

protocol AudioServiceProtocol {
    func playAudio(_ audioURL: URL) async throws
}

// MARK: - AI Response Model
struct AIResponse {
    let text: String
    let audioURL: URL?
}

// MARK: - Mock Implementations
class AIService: AIServiceProtocol {
    func generateResponse(messages: [Message]) async throws -> AIResponse {
        try await Task.sleep(nanoseconds: 1_500_000_000)
        let fallbackText = [
            "很好的表达！让我们继续练习。",
            "这是一个不错的话题，你可以提供更多细节吗？",
            "你的发音听起来很自然，保持这个状态。"
        ].randomElement() ?? "好的，我们继续。"
        return AIResponse(text: fallbackText, audioURL: nil)
    }
}

class AudioService: AudioServiceProtocol {
    private var player: AVAudioPlayer?
    
    func playAudio(_ audioURL: URL) async throws {
        let data = try Data(contentsOf: audioURL)
        player = try AVAudioPlayer(data: data)
        player?.play()
    }
}
