//
//  HomeView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // 顶部标题栏
                    headerView
                    
                    // 搜索框
                    SearchBar(text: $viewModel.searchText, placeholder: "搜索单词、短语或句子...")
                    
                    // 学习进度卡片
                    if userViewModel.isLoading {
                        ProgressCardSkeleton()
                    } else {
                        ProgressCard(
                            progress: viewModel.learningProgress,
                            studyHours: viewModel.studyHours,
                            daysLeft: viewModel.daysLeft
                        )
                    }
                    
                    // 功能按钮网格
                    functionalButtons
                    
                    // 每日推荐
                    dailyRecommendation
                    
                    // 今日单词
                    todayWords
                    
                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $viewModel.showChatView) {
            ChatView()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // 顶部标题栏
    private var headerView: some View {
        HStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text("晚上好")
                    .font(AppFonts.subheadline)
                    .foregroundColor(AppColors.secondary)
                Text("AI 口语练习")
                    .font(AppFonts.title1)
                    .foregroundColor(AppColors.primary)
            }
            
            Spacer()
            
            Button(action: {
                showingSettings = true
            }) {
                Circle()
                    .fill(AppColors.surface)
                    .frame(width: 40, height: 40)
                    .shadow(color: AppShadow.subtle, radius: 8, x: 0, y: 4)
                    .overlay(
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.accent)
                    )
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
    
    
    
    // 功能按钮网格
    private var functionalButtons: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 2), spacing: AppSpacing.md) {
            FunctionButton(icon: "bubble.left.and.bubble.right", title: "口语对话") {
                viewModel.startConversation()
            }
            FunctionButton(icon: "book", title: "背单词") {
                viewModel.startWordPractice()
            }
            FunctionButton(icon: "mic", title: "跟读练习") {
                viewModel.startSpeakingPractice()
            }
            FunctionButton(icon: "pencil", title: "作文批改") {
                viewModel.startWritingCorrection()
            }
        }
    }
    
    // 每日推荐
    private var dailyRecommendation: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("每日推荐")
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Button(action: {}) {
                    Text("更多")
                        .font(AppFonts.footnote)
                        .foregroundColor(AppColors.accent)
                }
            }
            
            RecommendationCard(
                title: "商务英语对话练习",
                description: "练习商务场合的英语表达，提升职场竞争力",
                duration: "15分钟",
                level: "中级"
            ) {
                viewModel.startRecommendedPractice()
            }
        }
    }
    
    // 今日单词
    private var todayWords: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Text("今日单词")
                    .font(AppFonts.title3)
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Button("切换词库") {
                    viewModel.switchWordLibrary()
                }
                .font(AppFonts.footnote)
                .foregroundColor(AppColors.secondary)
            }
            
            // 单词卡片占位符
            RoundedRectangle(cornerRadius: AppRadius.md)
                .fill(AppColors.cardBackground)
                .frame(height: 120)
                .shadow(color: AppShadow.subtle, radius: 8, x: 0, y: 2)
                .overlay(
                    VStack(spacing: AppSpacing.xs) {
                        Image(systemName: "abc")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(AppColors.secondary)
                        
                        Text("单词学习即将上线")
                            .font(AppFonts.subheadline)
                            .foregroundColor(AppColors.secondary)
                    }
                )
        }
    }
}


#Preview {
    HomeView()
}
