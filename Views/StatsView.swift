//
//  StatsView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppSpacing.xl) {
                    // 时间范围选择器
                    timeRangeSelector
                    
                    if viewModel.isLoading {
                        loadingView
                    } else {
                        // 核心统计数据
                        coreStatsGrid
                        
                        // 学习进度图表
                        progressChart
                        
                        // 成就和里程碑
                        achievementsSection
                        
                        // 详细统计
                        detailedStats
                    }
                    
                    Spacer(minLength: AppSpacing.xl)
                }
                .padding(.horizontal, AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle("学习统计")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.loadStats()
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    // MARK: - 时间范围选择器
    private var timeRangeSelector: some View {
        HStack(spacing: AppSpacing.xs) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(range.rawValue) {
                    viewModel.changeTimeRange(range)
                }
                .font(AppFonts.subheadline)
                .fontWeight(.medium)
                .foregroundColor(viewModel.selectedTimeRange == range ? .white : AppColors.secondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    viewModel.selectedTimeRange == range ? 
                    AppColors.accent : AppColors.secondaryBackground
                )
                .cornerRadius(AppRadius.lg)
            }
            
            Spacer()
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        VStack(spacing: AppSpacing.lg) {
            ForEach(0..<3, id: \.self) { _ in
                StatsCardSkeleton()
            }
        }
    }
    
    // MARK: - 核心统计网格
    private var coreStatsGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 2), spacing: AppSpacing.md) {
            StatsCard(
                title: "学习时长",
                value: viewModel.totalStudyTimeFormatted,
                icon: "clock",
                color: AppColors.accent
            )
            
            StatsCard(
                title: "连续天数",
                value: viewModel.currentStreakText,
                icon: "flame",
                color: AppColors.success
            )
            
            StatsCard(
                title: "对话次数",
                value: "\(viewModel.learningStats?.conversationsCompleted ?? 0)次",
                icon: "bubble.left.and.bubble.right",
                color: AppColors.accent
            )
            
            StatsCard(
                title: "发音准确度",
                value: "\(viewModel.pronunciationScorePercentage)%",
                icon: "waveform",
                color: AppColors.success
            )
        }
    }
    
    // MARK: - 进度图表
    private var progressChart: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("学习进度")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            WeeklyProgressChart(progress: viewModel.weeklyProgress)
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.lg)
        .shadow(color: AppShadow.subtle, radius: 16, x: 0, y: 8)
    }
    
    // MARK: - 成就部分
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("成就")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 3), spacing: AppSpacing.sm) {
                AchievementBadge(
                    title: "初学者",
                    description: "完成首次对话",
                    isUnlocked: true,
                    icon: "star"
                )
                
                AchievementBadge(
                    title: "坚持者",
                    description: "连续学习7天",
                    isUnlocked: (viewModel.learningStats?.currentStreak ?? 0) >= 7,
                    icon: "calendar"
                )
                
                AchievementBadge(
                    title: "专家",
                    description: "完成50次对话",
                    isUnlocked: (viewModel.learningStats?.conversationsCompleted ?? 0) >= 50,
                    icon: "graduationcap"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.lg)
        .shadow(color: AppShadow.subtle, radius: 16, x: 0, y: 8)
    }
    
    // MARK: - 详细统计
    private var detailedStats: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("详细数据")
                .font(AppFonts.title3)
                .foregroundColor(AppColors.primary)
            
            VStack(spacing: AppSpacing.sm) {
                DetailedStatRow(
                    title: "平均会话时长",
                    value: formatSessionTime(viewModel.learningStats?.averageSessionTime ?? 0)
                )
                
                DetailedStatRow(
                    title: "总会话次数",
                    value: "\(viewModel.learningStats?.totalSessions ?? 0)次"
                )
                
                DetailedStatRow(
                    title: "学习词汇量",
                    value: "\(viewModel.learningStats?.wordsLearned ?? 0)个"
                )
                
                DetailedStatRow(
                    title: "最长连续天数",
                    value: "\(viewModel.learningStats?.longestStreak ?? 0)天"
                )
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.md)
        .shadow(color: AppShadow.subtle, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    private func formatSessionTime(_ time: TimeInterval) -> String {
        let minutes = Int(time / 60)
        return "\(minutes)分钟"
    }
}

// MARK: - Stats Card Component
struct StatsCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .light))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: AppSpacing.xxs) {
                Text(value)
                    .font(AppFonts.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primary)
                
                Text(title)
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.md)
        .shadow(color: AppShadow.subtle, radius: 8, x: 0, y: 2)
    }
}

// MARK: - Stats Card Skeleton
struct StatsCardSkeleton: View {
    @State private var animating = false
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Circle()
                .fill(AppColors.secondaryBackground)
                .frame(width: 48, height: 48)
                .opacity(animating ? 0.3 : 0.6)
            
            VStack(spacing: AppSpacing.xxs) {
                RoundedRectangle(cornerRadius: AppRadius.xxs)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 60, height: 24)
                    .opacity(animating ? 0.3 : 0.6)
                
                RoundedRectangle(cornerRadius: AppRadius.xxs)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 40, height: 12)
                    .opacity(animating ? 0.3 : 0.6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.lg)
        .background(AppColors.cardBackground)
        .cornerRadius(AppRadius.md)
        .shadow(color: AppShadow.subtle, radius: 8, x: 0, y: 2)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                animating = true
            }
        }
    }
}

// MARK: - Achievement Badge
struct AchievementBadge: View {
    let title: String
    let description: String
    let isUnlocked: Bool
    let icon: String
    
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .light))
                .foregroundColor(isUnlocked ? AppColors.accent : AppColors.tertiary)
                .frame(width: 40, height: 40)
                .background((isUnlocked ? AppColors.accent : AppColors.tertiary).opacity(0.1))
                .clipShape(Circle())
            
            VStack(spacing: AppSpacing.xxs) {
                Text(title)
                    .font(AppFonts.caption1)
                    .fontWeight(.medium)
                    .foregroundColor(isUnlocked ? AppColors.primary : AppColors.tertiary)
                
                Text(description)
                    .font(AppFonts.caption2)
                    .foregroundColor(AppColors.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .padding(AppSpacing.sm)
        .opacity(isUnlocked ? 1.0 : 0.6)
    }
}

// MARK: - Detailed Stat Row
struct DetailedStatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(AppFonts.callout)
                .foregroundColor(AppColors.primary)
            
            Spacer()
            
            Text(value)
                .font(AppFonts.callout)
                .fontWeight(.medium)
                .foregroundColor(AppColors.secondary)
        }
        .padding(.vertical, AppSpacing.xxs)
    }
}

// MARK: - Weekly Progress Chart
struct WeeklyProgressChart: View {
    let progress: [DayProgress]
    
    var body: some View {
        HStack(alignment: .bottom, spacing: AppSpacing.xs) {
            ForEach(progress, id: \.date) { dayProgress in
                VStack(spacing: AppSpacing.xxs) {
                    RoundedRectangle(cornerRadius: AppRadius.xxs)
                        .fill(dayProgress.isCompleted ? AppColors.accent : AppColors.secondaryBackground)
                        .frame(width: 32, height: max(8, CGFloat(dayProgress.studyTime / 3600 * 60)))
                        .animation(.easeInOut(duration: 0.5), value: dayProgress.studyTime)
                    
                    Text(dayAbbreviation(dayProgress.date))
                        .font(AppFonts.caption2)
                        .foregroundColor(AppColors.secondary)
                }
            }
        }
        .frame(height: 80)
    }
    
    private func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "zh_CN")
        return String(formatter.string(from: date).prefix(1))
    }
}

#Preview {
    StatsView()
}


