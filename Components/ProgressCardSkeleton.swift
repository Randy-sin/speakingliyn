//
//  ProgressCardSkeleton.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct ProgressCardSkeleton: View {
    @State private var animating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                RoundedRectangle(cornerRadius: AppRadius.xxs)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 120, height: 20)
                    .opacity(animating ? 0.3 : 0.6)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: AppRadius.xxs)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 40, height: 20)
                    .opacity(animating ? 0.3 : 0.6)
            }
            
            // 进度条骨架
            RoundedRectangle(cornerRadius: AppRadius.full)
                .fill(AppColors.secondaryBackground)
                .frame(height: 8)
                .opacity(animating ? 0.3 : 0.6)
            
            HStack {
                RoundedRectangle(cornerRadius: AppRadius.xxs)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 80, height: 16)
                    .opacity(animating ? 0.3 : 0.6)
                
                Spacer()
                
                RoundedRectangle(cornerRadius: AppRadius.xxs)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 100, height: 16)
                    .opacity(animating ? 0.3 : 0.6)
            }
        }
        .padding(AppSpacing.xl)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.lg)
        .shadow(color: AppShadow.subtle, radius: 12, x: 0, y: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }
}

#Preview {
    ProgressCardSkeleton()
        .padding()
        .background(AppColors.groupedBackground)
}

