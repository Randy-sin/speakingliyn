//
//  TypingIndicator.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct TypingIndicator: View {
    @State private var animating = false
    
    var body: some View {
        HStack {
            HStack(alignment: .top, spacing: AppSpacing.xs) {
                // AI头像
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 32, height: 32)
                    .background(AppColors.secondaryBackground)
                    .clipShape(Circle())
                
                // 输入指示器
                HStack(spacing: AppSpacing.xxs) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(AppColors.secondary)
                            .frame(width: 6, height: 6)
                            .scaleEffect(animating ? 1.0 : 0.5)
                            .opacity(animating ? 0.8 : 0.4)
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animating
                            )
                    }
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.secondaryBackground)
                .cornerRadius(AppRadius.md)
                .cornerRadius(AppRadius.xxs, corners: .bottomLeft)
            }
            
            Spacer(minLength: 50)
        }
        .padding(.horizontal, AppSpacing.md)
        .onAppear {
            animating = true
        }
        .onDisappear {
            animating = false
        }
    }
}

#Preview {
    TypingIndicator()
        .padding()
        .background(AppColors.background)
}

