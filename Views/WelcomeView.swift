//
//  WelcomeView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct WelcomeView: View {
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButton = false
    @State private var showChatApp = false
    
    var body: some View {
        ZStack {
            // 背景
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppSpacing.xxxl) {
                Spacer()
                
                // Logo区域
                VStack(spacing: AppSpacing.xl) {
                    // 简洁的图标
                    Image(systemName: "waveform")
                        .font(.system(size: 80, weight: .ultraLight))
                        .foregroundColor(AppColors.accent)
                        .scaleEffect(animateTitle ? 1.0 : 0.8)
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 1.0).delay(0.2), value: animateTitle)
                    
                    // 标题
                    Text("Speaking")
                        .font(AppFonts.largeTitle)
                        .foregroundColor(AppColors.primary)
                        .scaleEffect(animateTitle ? 1.0 : 0.9)
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.8).delay(0.5), value: animateTitle)
                    
                    // 副标题
                    Text("AI助手让口语练习更简单")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.secondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateSubtitle ? 1.0 : 0.0)
                        .offset(y: animateSubtitle ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateSubtitle)
                }
                
                Spacer()
                
                // 开始按钮
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showChatApp = true
                    }
                }) {
                    HStack(spacing: AppSpacing.xs) {
                        Text("开始使用")
                            .font(AppFonts.headline)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppSpacing.xxl)
                    .padding(.vertical, AppSpacing.md)
                    .background(AppColors.accent)
                    .cornerRadius(AppRadius.md)
                }
                .scaleEffect(animateButton ? 1.0 : 0.9)
                .opacity(animateButton ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(1.1), value: animateButton)
                
                Spacer(minLength: AppSpacing.xxxl)
            }
            .padding(.horizontal, AppSpacing.xl)
        }
        .fullScreenCover(isPresented: $showChatApp) {
            ChatView()
        }
        .onAppear {
            animateTitle = true
            animateSubtitle = true
            animateButton = true
        }
    }
}

#Preview {
    WelcomeView()
}

