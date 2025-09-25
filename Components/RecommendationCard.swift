//
//  RecommendationCard.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct RecommendationCard: View {
    let title: String
    let description: String
    let duration: String
    let level: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "lightbulb")
                .font(.system(size: 20, weight: .light))
                .foregroundColor(AppColors.accent)
                .frame(width: 44, height: 44)
                .background(AppColors.surface)
                .clipShape(Circle())
                .shadow(color: AppShadow.subtle, radius: 12, x: 0, y: 6)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFonts.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.primary)
                
                Text(description)
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.secondary)
                    .lineLimit(2)
                
                HStack(spacing: AppSpacing.sm) {
                    Label(duration, systemImage: "clock")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.tertiary)
                    
                    Label(level, systemImage: "chart.bar")
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.tertiary)
                }
            }
            
            Spacer()
            
            Button("开始", action: action)
                .font(AppFonts.caption1)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColors.accent)
                .cornerRadius(AppRadius.sm)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.lg)
        .shadow(color: AppShadow.subtle, radius: 16, x: 0, y: 8)
    }
}

#Preview {
    RecommendationCard(
        title: "商务英语对话练习",
        description: "练习商务场合的英语表达，提升职场竞争力",
        duration: "15分钟",
        level: "中级"
    ) {}
    .padding()
    .background(AppColors.background)
}
