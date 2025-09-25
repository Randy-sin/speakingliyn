//
//  ChatInputView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct ChatInputView: View {
    @Binding var inputText: String
    let onSendMessage: () -> Void
    let onStartRecording: () -> Void
    let onStopRecording: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            // 输入框
            ZStack(alignment: .leading) {
                if inputText.isEmpty {
                    Text("输入消息或按住说话...")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.tertiary)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                }
                TextField("", text: $inputText, axis: .vertical)
                    .font(AppFonts.callout)
                    .lineLimit(1...4)
                    .padding(.horizontal, AppSpacing.sm)
                    .padding(.vertical, AppSpacing.xs)
            }
            .background(AppColors.surface)
            .cornerRadius(AppRadius.lg)
            .shadow(color: AppShadow.subtle, radius: 12, x: 0, y: 6)
            .overlay(alignment: .trailing) {
                Button(action: onStartRecording) {
                    Image(systemName: "mic.circle.fill")
                        .font(.system(size: 28, weight: .regular))
                        .foregroundColor(AppColors.accent)
                        .padding(AppSpacing.sm)
                }
            }
            
            // 发送按钮
            Button(action: onSendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(inputText.isEmpty ? AppColors.tertiary : AppColors.accent)
            }
            .disabled(inputText.isEmpty)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColors.background)
    }
}

#Preview {
    @State var inputText = ""
    return ChatInputView(
        inputText: $inputText,
        onSendMessage: {},
        onStartRecording: {},
        onStopRecording: {}
    )
    .background(AppColors.groupedBackground)
}

