//
//  TopicsView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct TopicsView: View {
    @StateObject private var viewModel = TopicsViewModel()
    @State private var showingTopicDetail = false
    @State private var selectedTopic: PracticeTopic?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索框
                searchSection
                
                // 分类筛选
                categorySection
                
                // 话题列表
                topicsContent
            }
            .background(AppColors.background)
            .navigationTitle("练习话题")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.loadTopics()
            }
        }
        .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("确定") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(item: $selectedTopic) { topic in
            TopicDetailView(topic: topic) {
                viewModel.startPractice(with: topic)
                selectedTopic = nil
            }
        }
    }
    
    // MARK: - 搜索部分
    private var searchSection: some View {
        VStack(spacing: AppSpacing.sm) {
            SearchBar(text: $viewModel.searchText, placeholder: "搜索话题...")
                .padding(.horizontal, AppSpacing.lg)
            
            Divider()
                .background(AppColors.cardBorder)
        }
        .padding(.top, AppSpacing.sm)
        .background(AppColors.background)
    }
    
    // MARK: - 分类部分
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                // 全部分类按钮
                CategoryChip(
                    title: "全部",
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectCategory(nil)
                }
                
                // 其他分类
                ForEach(viewModel.categories) { category in
                    CategoryChip(
                        title: category.name,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.lg)
        }
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.background)
    }
    
    // MARK: - 话题内容
    private var topicsContent: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.topics.isEmpty {
                emptyView
            } else {
                topicsList
            }
        }
    }
    
    // MARK: - 加载视图
    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(0..<6, id: \.self) { _ in
                    TopicCardSkeleton()
                }
            }
            .padding(AppSpacing.lg)
        }
    }
    
    // MARK: - 空状态视图
    private var emptyView: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .ultraLight))
                .foregroundColor(AppColors.tertiary)
            
            VStack(spacing: AppSpacing.xs) {
                Text("没有找到相关话题")
                    .font(AppFonts.headline)
                    .foregroundColor(AppColors.primary)
                
                Text("试试其他关键词或选择不同分类")
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
        .padding(AppSpacing.xl)
    }
    
    // MARK: - 话题列表
    private var topicsList: some View {
        ScrollView {
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(viewModel.topics) { topic in
                    TopicCard(topic: topic) {
                        selectedTopic = topic
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFonts.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : AppColors.secondary)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(
                    isSelected ? AppColors.accent : AppColors.secondaryBackground
                )
                .cornerRadius(AppRadius.lg)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Topic Card
struct TopicCard: View {
    let topic: PracticeTopic
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                // 头部信息
                HStack {
                    Image(systemName: topic.icon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(topic.category.color)
                        .frame(width: 40, height: 40)
                        .background(topic.category.color.opacity(0.1))
                        .cornerRadius(AppRadius.sm)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        HStack {
                            Text(topic.title)
                                .font(AppFonts.headline)
                                .foregroundColor(AppColors.primary)
                                .lineLimit(1)
                            
                            if topic.isPopular {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.warning)
                            }
                        }
                        
                        Text(topic.category.name)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                        DifficultyBadge(difficulty: topic.difficulty)
                        
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.tertiary)
                            
                            Text("\(topic.estimatedTime)分钟")
                                .font(AppFonts.caption2)
                                .foregroundColor(AppColors.tertiary)
                        }
                    }
                }
                
                // 描述
                Text(topic.description)
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // 关键词
                if !topic.keywords.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(topic.keywords.prefix(3), id: \.self) { keyword in
                                Text(keyword)
                                    .font(AppFonts.caption2)
                                    .foregroundColor(AppColors.secondary)
                                    .padding(.horizontal, AppSpacing.xs)
                                    .padding(.vertical, 2)
                                    .background(AppColors.secondaryBackground)
                                    .cornerRadius(AppRadius.xs)
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.lg)
            .background(AppColors.surface)
            .cornerRadius(AppRadius.lg)
            .shadow(color: AppShadow.subtle, radius: 16, x: 0, y: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Difficulty Badge
struct DifficultyBadge: View {
    let difficulty: TopicDifficulty
    
    var body: some View {
        Text(difficulty.rawValue)
            .font(AppFonts.caption2)
            .fontWeight(.medium)
            .foregroundColor(difficulty.color)
            .padding(.horizontal, AppSpacing.xs)
            .padding(.vertical, 2)
            .background(difficulty.color.opacity(0.1))
            .cornerRadius(AppRadius.xs)
    }
}

// MARK: - Topic Card Skeleton
struct TopicCardSkeleton: View {
    @State private var animating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 40, height: 40)
                    .opacity(animating ? 0.3 : 0.6)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    RoundedRectangle(cornerRadius: AppRadius.xxs)
                        .fill(AppColors.secondaryBackground)
                        .frame(width: 120, height: 16)
                        .opacity(animating ? 0.3 : 0.6)
                    
                    RoundedRectangle(cornerRadius: AppRadius.xxs)
                        .fill(AppColors.secondaryBackground)
                        .frame(width: 80, height: 12)
                        .opacity(animating ? 0.3 : 0.6)
                }
                
                Spacer()
                
                RoundedRectangle(cornerRadius: AppRadius.xs)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 40, height: 20)
                    .opacity(animating ? 0.3 : 0.6)
            }
            
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                RoundedRectangle(cornerRadius: AppRadius.xxs)
                    .fill(AppColors.secondaryBackground)
                    .frame(height: 16)
                    .opacity(animating ? 0.3 : 0.6)
                
                RoundedRectangle(cornerRadius: AppRadius.xxs)
                    .fill(AppColors.secondaryBackground)
                    .frame(width: 200, height: 16)
                    .opacity(animating ? 0.3 : 0.6)
            }
        }
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

// MARK: - Topic Detail View
struct TopicDetailView: View {
    let topic: PracticeTopic
    let onStartPractice: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.xl) {
                    // 话题标题和信息
                    topicHeader
                    
                    // 话题描述
                    topicDescription
                    
                    // 学习要点
                    learningPoints
                    
                    // 开始练习按钮
                    startButton
                }
                .padding(AppSpacing.lg)
            }
            .background(AppColors.groupedBackground)
            .navigationTitle(topic.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
    
    private var topicHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Image(systemName: topic.icon)
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(topic.category.color)
                    .frame(width: 60, height: 60)
                    .background(topic.category.color.opacity(0.1))
                    .cornerRadius(AppRadius.md)
                
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(topic.category.name)
                        .font(AppFonts.subheadline)
                        .foregroundColor(AppColors.secondary)
                    
                    HStack(spacing: AppSpacing.sm) {
                        DifficultyBadge(difficulty: topic.difficulty)
                        
                        HStack(spacing: AppSpacing.xxs) {
                            Image(systemName: "clock")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.tertiary)
                            
                            Text("\(topic.estimatedTime)分钟")
                                .font(AppFonts.caption1)
                                .foregroundColor(AppColors.tertiary)
                        }
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private var topicDescription: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("话题介绍")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            Text(topic.description)
                .font(AppFonts.callout)
                .foregroundColor(AppColors.secondary)
                .lineSpacing(4)
        }
    }
    
    private var learningPoints: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("学习要点")
                .font(AppFonts.headline)
                .foregroundColor(AppColors.primary)
            
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                ForEach(topic.keywords, id: \.self) { keyword in
                    HStack(spacing: AppSpacing.sm) {
                        Circle()
                            .fill(AppColors.accent)
                            .frame(width: 6, height: 6)
                        
                        Text(keyword)
                            .font(AppFonts.callout)
                            .foregroundColor(AppColors.primary)
                        
                        Spacer()
                    }
                }
            }
        }
    }
    
    private var startButton: some View {
        Button(action: onStartPractice) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 20))
                
                Text("开始练习")
                    .font(AppFonts.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.accent)
            .cornerRadius(AppRadius.md)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    TopicsView()
}


