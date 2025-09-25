//
//  ChatView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingVoiceAssistant = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                chatList
                Divider().background(AppColors.cardBorder)
                chatInput
            }
            .background(AppColors.background)
            .navigationTitle("AI 对话")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完成") { dismiss() }
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.accent)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("清除对话") { viewModel.clearChat() }
                        Button("分享对话") { viewModel.shareChat() }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppColors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingVoiceAssistant) {
            VoiceAssistantView(
                onStop: {
                    viewModel.stopRecording()
                    showingVoiceAssistant = false
                },
                onCancel: {
                    viewModel.cancelRecording()
                    showingVoiceAssistant = false
                }
            )
            .onAppear { viewModel.startRecording() }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: AppSpacing.sm) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message) { audioURL in
                            viewModel.playAudio(url: audioURL)
                        }
                        .id(message.id)
                    }
                    if viewModel.isLoading { TypingIndicator() }
                }
                .padding(.vertical, AppSpacing.md)
            }
            .background(AppColors.background)
            .onChange(of: viewModel.messages.count) { _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var chatInput: some View {
        ChatInputView(
            inputText: $viewModel.inputText,
            onSendMessage: viewModel.sendMessage,
            onStartRecording: {
                showingVoiceAssistant = true
            },
            onStopRecording: {}
        )
        .padding(.bottom, viewModel.keyboardHeight > 0 ? 0 : AppSpacing.xs)
    }
}

#Preview { ChatView() }
