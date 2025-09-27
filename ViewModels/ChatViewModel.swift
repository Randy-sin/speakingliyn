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
    private let streamingASRService: StreamingASRServiceProtocol
    private var currentRecordingURL: URL?
    
    // MARK: - Init
    init(
        aiService: AIServiceProtocol,
        audioPlayerService: AudioServiceProtocol,
        streamingASRService: StreamingASRServiceProtocol
    ) {
        self.aiService = aiService
        self.audioPlayerService = audioPlayerService
        self.streamingASRService = streamingASRService
        setupInitialMessage()
        setupKeyboardObservers()
        setupStreamingASRCallbacks()
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
        
        // 立即更新UI状态，提供即时反馈
        isRecording = true
        print("[Voice] 开始流式语音识别")
        
        Task {
            do {
                try await streamingASRService.startStreaming()
                print("[Voice] 流式识别已启动")
            } catch {
                await MainActor.run {
                    self.isRecording = false
                    self.errorMessage = "开始语音识别失败：\(error.localizedDescription)"
                }
                print("[Voice][Error] startStreaming failed: \(error)")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else {
            print("[Voice] stopRecording ignored, isRecording = false")
            return
        }
        
        isRecording = false
        print("[Voice] 手动停止流式识别")
        
        Task {
            do {
                try await streamingASRService.stopStreaming()
                print("[Voice] 流式识别已停止")
            } catch {
                await MainActor.run {
                    self.errorMessage = "停止语音识别失败：\(error.localizedDescription)"
                }
                print("[Voice][Error] stopStreaming failed: \(error)")
            }
        }
    }
    
    func cancelRecording() {
        guard isRecording else { return }
        
        // 立即更新UI状态
        isRecording = false
        print("[Voice] 取消流式识别")
        
        Task {
            do {
                try await streamingASRService.stopStreaming()
                print("[Voice] 流式识别已取消")
            } catch {
                print("[Voice][Error] 取消流式识别失败: \(error)")
            }
        }
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
    
    private func setupStreamingASRCallbacks() {
        // 部分识别结果回调（立即触发界面关闭）
        streamingASRService.onPartialResult = { [weak self] partialText in
            print("[StreamASR] 检测到断句，立即关闭界面: \(partialText)")
            Task {
                await MainActor.run {
                    self?.isRecording = false  // 立即关闭语音界面
                }
            }
        }
        
        // 最终识别结果回调（后台识别完成，添加消息并触发AI回复）
        streamingASRService.onFinalResult = { [weak self] finalText in
            print("[StreamASR] 后台识别完成: \(finalText)")
            Task {
                await MainActor.run {
                    guard let self = self else { return }
                    
                    if !finalText.isEmpty {
                        let userMessage = Message(text: finalText, isFromUser: true)
                        self.messages.append(userMessage)
                        self.processConversation() // 自动触发AI回复
                    }
                }
            }
        }
        
        // 错误处理回调
        streamingASRService.onError = { [weak self] error in
            print("[StreamASR][Error] \(error.localizedDescription)")
            Task {
                await MainActor.run {
                    self?.isRecording = false
                    self?.errorMessage = "语音识别错误：\(error.localizedDescription)"
                }
            }
        }
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
