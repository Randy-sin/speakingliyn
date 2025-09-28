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
    let recognitionText: String // 实时识别的文字
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
            
            VStack(spacing: 0) {
                header
                
                Spacer(minLength: 60)
                
                VStack(spacing: AppSpacing.xxxl) {
                    animatedOrb
                    promptSection
                }
                
                Spacer(minLength: 80)
                
                actionButtons
                    .padding(.bottom, 40)
            }
            .padding(.horizontal, AppSpacing.xxl)
        }
        .interactiveDismissDisabled(true)
        .statusBarHidden()
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                waveformPhase = 40
            }
        }
    }
    
    private var header: some View {
        HStack {
            Spacer()
            Button(action: cancelAction) {
                headerButton(icon: "xmark")
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 20)
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
                        startRadius: 60,
                        endRadius: 200
                    )
                )
                .frame(width: 320, height: 320)
                .shadow(color: AppShadow.light, radius: 60, x: 0, y: 30)
                .overlay(
                    Circle()
                        .stroke(AppColors.accent.opacity(0.18), lineWidth: 28)
                )
            
            Circle()
                .stroke(AppColors.accent.opacity(0.4), style: StrokeStyle(lineWidth: 4, dash: [16, 20], dashPhase: waveformPhase))
                .frame(width: 360, height: 360)
                .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: waveformPhase)
        }
    }
    
    private var promptSection: some View {
        VStack(spacing: AppSpacing.md) {
            Text(isListening ? "我正在聆听" : "点击继续语音")
                .font(AppFonts.title1)
                .fontWeight(.semibold)
                .foregroundColor(AppColors.primary)
            
            Text("请说出你想练习的内容\n系统会自动检测语音结束")
                .font(AppFonts.body)
                .foregroundColor(AppColors.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            // 实时识别结果显示
            if !recognitionText.isEmpty {
                Text(recognitionText)
                    .font(AppFonts.title2)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.accent)
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.vertical, AppSpacing.sm)
                    .background(AppColors.surface.opacity(0.9))
                    .cornerRadius(AppRadius.lg)
                    .animation(.easeInOut(duration: 0.2), value: recognitionText)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
    }
    
    private var actionButtons: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.xl) {
                Button(action: { isListening.toggle() }) {
                    actionButton(
                        icon: isListening ? "pause.circle.fill" : "mic.fill", 
                        title: isListening ? "暂停" : "继续", 
                        tint: AppColors.primary
                    )
                }
                
                Button(action: stopAction) {
                    actionButton(
                        icon: "stop.circle.fill", 
                        title: "完成", 
                        tint: AppColors.accent
                    )
                }
            }
            
            Text("正在使用 AI 智能识别")
                .font(AppFonts.caption1)
                .foregroundColor(AppColors.tertiary.opacity(0.8))
        }
    }
    
    private func actionButton(icon: String, title: String, tint: Color) -> some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .semibold))
            Text(title)
                .font(AppFonts.callout)
                .fontWeight(.medium)
        }
        .foregroundColor(tint)
        .frame(width: 100, height: 100)
        .background(AppColors.surface.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous))
        .shadow(color: AppShadow.light, radius: 20, x: 0, y: 15)
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
    VoiceAssistantView(recognitionText: "正在识别语音...")
}
