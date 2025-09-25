//
//  VoiceAssistantView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct VoiceAssistantView: View {
    var onStop: (() -> Void)?
    var onCancel: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var isListening = true
    @State private var waveformPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.voiceGradientStart,
                    AppColors.voiceGradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxxl) {
                header
                animatedOrb
                promptSection
                actionButtons
            }
            .padding(.horizontal, AppSpacing.xxl)
            .padding(.vertical, AppSpacing.xxxl)
        }
        .interactiveDismissDisabled(true)
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                waveformPhase = 40
            }
        }
    }
    
    private var header: some View {
        HStack {
            Button(action: cancelAction) {
                headerButton(icon: "chevron.down")
            }
            Spacer()
            Text("语音练习")
                .font(AppFonts.subheadline)
                .foregroundColor(AppColors.secondary)
            Spacer()
            Button(action: cancelAction) {
                headerButton(icon: "xmark")
            }
        }
    }
    
    private func headerButton(icon: String) -> some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(AppColors.primary)
            .padding(10)
            .background(AppColors.surface.opacity(0.8))
            .clipShape(Circle())
            .shadow(color: AppShadow.subtle, radius: 8, x: 0, y: 4)
    }
    
    private var animatedOrb: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            AppColors.subtleGradientEnd,
                            AppColors.gradientStart
                        ]),
                        center: .center,
                        startRadius: 40,
                        endRadius: 160
                    )
                )
                .frame(width: 260, height: 260)
                .shadow(color: AppShadow.light, radius: 40, x: 0, y: 20)
                .overlay(
                    Circle()
                        .stroke(AppColors.accent.opacity(0.18), lineWidth: 22)
                )
            
            Circle()
                .stroke(AppColors.accent.opacity(0.4), style: StrokeStyle(lineWidth: 3, dash: [12, 16], dashPhase: waveformPhase))
                .frame(width: 280, height: 280)
                .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: waveformPhase)
        }
    }
    
    private var promptSection: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(isListening ? "我正在聆听" : "点击继续语音")
                .font(AppFonts.title2)
                .foregroundColor(AppColors.primary)
            
            Text("描述你想练习的场景，或直接开始说话")
                .font(AppFonts.callout)
                .foregroundColor(AppColors.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.md) {
                Button(action: { isListening.toggle() }) {
                    actionButton(icon: isListening ? "pause.circle.fill" : "mic.fill", title: isListening ? "暂停" : "继续", tint: AppColors.primary)
                }
                Button(action: {}) {
                    actionButton(icon: "square.and.arrow.up.fill", title: "上传", tint: AppColors.primary)
                }
                Button(action: {}) {
                    actionButton(icon: "video.circle.fill", title: "视频", tint: AppColors.primary)
                }
                Button(action: stopAction) {
                    actionButton(icon: "xmark.circle.fill", title: "结束", tint: AppColors.destructive)
                }
            }
            
            Text("内容由 AI 生成")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.tertiary)
        }
    }
    
    private func actionButton(icon: String, title: String, tint: Color) -> some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
            Text(title)
                .font(AppFonts.subheadline)
        }
        .foregroundColor(tint)
        .frame(width: 72, height: 72)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .shadow(color: AppShadow.light, radius: 12, x: 0, y: 10)
    }
    
    private func stopAction() {
        onStop?()
        dismiss()
    }
    
    private func cancelAction() {
        onCancel?()
        dismiss()
    }
}

#Preview {
    VoiceAssistantView()
}
