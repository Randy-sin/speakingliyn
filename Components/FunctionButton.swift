//
//  FunctionButton.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct FunctionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 48, height: 48)
                    .background(AppColors.secondaryBackground)
                    .clipShape(Circle())
                
                Text(title)
                    .font(AppFonts.footnote)
                    .foregroundColor(AppColors.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.md)
            .shadow(color: AppShadow.subtle, radius: 16, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
        FunctionButton(icon: "bubble.left.and.bubble.right", title: "口语对话") {}
        FunctionButton(icon: "book", title: "背单词") {}
        FunctionButton(icon: "mic", title: "跟读练习") {}
        FunctionButton(icon: "pencil", title: "作文批改") {}
    }
    .padding()
    .background(AppColors.background)
}

