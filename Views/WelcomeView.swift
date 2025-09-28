//
//  WelcomeView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct WelcomeView: View {
    @State private var animateContent = false
    @State private var showChatView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // 简洁的浅色背景
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // 主要内容区域
                    mainContentCard
                    
                    Spacer()
                    
                    // 底部操作区域
                    bottomActionArea
                        .padding(.bottom, AppSpacing.xxl)
                }
                .padding(.horizontal, AppSpacing.xl)
            }
        }
        .fullScreenCover(isPresented: $showChatView) {
            ChatView()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Main Content Card
    private var mainContentCard: some View {
        VStack(spacing: AppSpacing.xxl) {
            // 品牌标识区域
            brandSection
            
            // 功能介绍区域
            featureSection
        }
        .padding(.horizontal, AppSpacing.xl)
        .padding(.vertical, AppSpacing.xxxl * 1.5)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .fill(AppColors.surface)
                .shadow(color: AppShadow.subtle, radius: 20, x: 0, y: 8)
        )
        .scaleEffect(animateContent ? 1.0 : 0.96)
        .opacity(animateContent ? 1.0 : 0.0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }
    
    // MARK: - Brand Section
    private var brandSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // 简洁的图标
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.accent, AppColors.accent.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(animateContent ? 1.0 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: animateContent)
            
            // 应用标题
            Text("Speaking")
                .font(AppFonts.largeTitle)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primary)
            
            // 副标题
            Text("AI 口语练习助手")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.secondary)
        }
    }
    
    // MARK: - Feature Section
    private var featureSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // 主要功能描述
            Text("与 AI 对话练习，\n提升你的口语表达能力")
                .font(AppFonts.title3)
                .fontWeight(.medium)
                .foregroundColor(AppColors.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // 特性列表
            VStack(spacing: AppSpacing.md) {
                featureRow(
                    icon: "mic.and.signal.meter",
                    title: "智能语音识别",
                    description: "实时识别语音内容"
                )
                
                featureRow(
                    icon: "brain.head.profile",
                    title: "AI 智能回复", 
                    description: "个性化对话体验"
                )
                
                featureRow(
                    icon: "waveform",
                    title: "自动断句检测",
                    description: "流畅的语音交互"
                )
            }
            .padding(.top, AppSpacing.md)
        }
    }
    
    // MARK: - Feature Row
    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: AppSpacing.md) {
            // 图标
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.accent)
                .frame(width: 24, height: 24)
            
            // 文字内容
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.callout)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primary)
                
                Text(description)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, AppSpacing.xs)
    }
    
    // MARK: - Bottom Action Area
    private var bottomActionArea: some View {
        VStack(spacing: AppSpacing.lg) {
            // 主要操作按钮
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showChatView = true
                }
            }) {
                HStack(spacing: AppSpacing.sm) {
                    Text("开始使用")
                        .font(AppFonts.headline)
                        .fontWeight(.medium)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.xxl)
                .padding(.vertical, AppSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppRadius.full)
                        .fill(AppColors.accent)
                        .shadow(color: AppColors.accent.opacity(0.3), radius: 12, x: 0, y: 6)
                )
            }
            .scaleEffect(animateContent ? 1.0 : 0.9)
            .opacity(animateContent ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.6), value: animateContent)
            .buttonStyle(PressedButtonStyle())
            
            // 辅助信息
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.success)
                
                Text("无需注册，即开即用")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.secondary)
            }
            .opacity(animateContent ? 0.8 : 0.0)
            .animation(.easeOut(duration: 0.6).delay(0.8), value: animateContent)
        }
    }
}

// MARK: - Custom Button Style
struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Chat View Placeholder
struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ServiceContainer.shared.makeChatViewModel()
    @State private var showingVoiceAssistant = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()
                
                VStack {
                    Text("AI 口语练习")
                        .font(AppFonts.title1)
                        .foregroundColor(AppColors.primary)
                        .padding()
                    
                    Spacer()
                    
                    // 聊天内容区域
                    chatList
                    
                    Spacer()
                    
                    // 输入区域
                    chatInput
                        .padding(.horizontal)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingVoiceAssistant) {
            VoiceAssistantView(
                onStop: {
                    viewModel.stopRecording()
                    showingVoiceAssistant = false
                },
                onCancel: {
                    viewModel.cancelRecording()
                    showingVoiceAssistant = false
                },
                recognitionText: viewModel.currentRecognitionText
            )
            .onAppear { viewModel.startRecording() }
        }
        .onChange(of: viewModel.isRecording) {
            // 当语音识别自动完成时（isRecording变为false），自动关闭语音界面
            if !viewModel.isRecording && showingVoiceAssistant {
                print("[Voice] 语音识别完成，自动关闭界面")
                showingVoiceAssistant = false
            }
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
            .onChange(of: viewModel.messages.count) {
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

#Preview {
    WelcomeView()
}