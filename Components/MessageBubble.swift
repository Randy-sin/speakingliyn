//
//  MessageBubble.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct MessageBubble: View {
    let message: Message
    let onPlayAudio: ((URL) -> Void)?
    
    init(message: Message, onPlayAudio: ((URL) -> Void)? = nil) {
        self.message = message
        self.onPlayAudio = onPlayAudio
    }
    
    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer(minLength: 50)
                userMessage
            } else {
                aiMessage
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, AppSpacing.md)
    }
    
    private var userMessage: some View {
        VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
            Text(message.text)
                .font(AppFonts.callout)
                .foregroundColor(.white)
                .padding(AppSpacing.sm)
                .background(AppColors.accent)
                .cornerRadius(AppRadius.md)
                .cornerRadius(AppRadius.xxs, corners: .bottomRight)
            
            Text(timeString)
                .font(AppFonts.caption2)
                .foregroundColor(AppColors.tertiary)
        }
    }
    
    private var aiMessage: some View {
        HStack(alignment: .top, spacing: AppSpacing.xs) {
            // AI头像
            Image(systemName: "waveform")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(AppColors.accent)
                .frame(width: 32, height: 32)
                .background(AppColors.secondaryBackground)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(message.text)
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.primary)
                    .padding(AppSpacing.sm)
                    .background(AppColors.surface)
                    .cornerRadius(AppRadius.md)
                    .cornerRadius(AppRadius.xxs, corners: .bottomLeft)
                
                HStack(spacing: AppSpacing.xs) {
                    Text(timeString)
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.tertiary)
                    
                    if let audioURL = message.audioURL {
                        Button(action: {
                            onPlayAudio?(audioURL)
                        }) {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(AppColors.accent)
                        }
                    }
                }
            }
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: message.timestamp)
    }
}

// MARK: - 圆角扩展
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    VStack(spacing: AppSpacing.md) {
        MessageBubble(message: Message(text: "Hello, how can I help you today?", isFromUser: false))
        MessageBubble(message: Message(text: "I want to practice speaking English", isFromUser: true))
        MessageBubble(message: Message(text: "Great! Let's start with a simple conversation. What's your favorite hobby?", isFromUser: false))
    }
    .padding()
    .background(AppColors.groupedBackground)
}

