//
//  ProgressCard.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct ProgressCard: View {
    let progress: Double
    let studyHours: String
    let daysLeft: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("本周学习进度")
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(AppFonts.headline)
                    .foregroundColor(.white)
            }
            
            // 进度条
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle())
                .tint(.white)
                .background(Color.white.opacity(0.3))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .clipShape(Capsule())
            
            HStack {
                Text("已学习 \(studyHours) 小时")
                    .font(AppFonts.footnote)
                    .foregroundColor(.white.opacity(0.9))
                
                Spacer()
                
                Text("距离目标还差 \(daysLeft) 天")
                    .font(AppFonts.footnote)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(AppSpacing.xl)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    AppColors.gradientStart,
                    AppColors.gradientEnd
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(AppRadius.lg)
        .shadow(color: AppShadow.light, radius: 16, x: 0, y: 8)
    }
}

#Preview {
    ProgressCard(progress: 0.75, studyHours: "5.8", daysLeft: "1")
        .padding()
        .background(AppColors.groupedBackground)
}

