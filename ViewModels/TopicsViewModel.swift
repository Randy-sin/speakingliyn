//
//  TopicsViewModel.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI
import Combine

@MainActor
class TopicsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var topics: [PracticeTopic] = []
    @Published var categories: [TopicCategory] = []
    @Published var selectedCategory: TopicCategory?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var allTopics: [PracticeTopic] = []
    
    // MARK: - Init
    init() {
        setupBindings()
        loadTopics()
    }
    
    // MARK: - Public Methods
    func loadTopics() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let (loadedTopics, loadedCategories) = try await fetchTopicsAndCategories()
                
                await MainActor.run {
                    self.allTopics = loadedTopics
                    self.categories = loadedCategories
                    self.topics = loadedTopics
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载话题失败：\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func selectCategory(_ category: TopicCategory?) {
        selectedCategory = category
        filterTopics()
    }
    
    func startPractice(with topic: PracticeTopic) {
        // 开始练习指定话题
        print("开始练习话题：\(topic.title)")
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // 监听搜索文本变化
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.filterTopics()
            }
            .store(in: &cancellables)
    }
    
    private func filterTopics() {
        var filteredTopics = allTopics
        
        // 按分类筛选
        if let category = selectedCategory {
            filteredTopics = filteredTopics.filter { $0.category == category }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            filteredTopics = filteredTopics.filter { topic in
                topic.title.localizedCaseInsensitiveContains(searchText) ||
                topic.description.localizedCaseInsensitiveContains(searchText) ||
                topic.keywords.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        topics = filteredTopics
    }
    
    private func fetchTopicsAndCategories() async throws -> ([PracticeTopic], [TopicCategory]) {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let categories = TopicCategory.allCategories
        let topics = PracticeTopic.sampleTopics
        
        return (topics, categories)
    }
}

// MARK: - Models
struct PracticeTopic: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: TopicCategory
    let difficulty: TopicDifficulty
    let estimatedTime: Int // 分钟
    let keywords: [String]
    let icon: String
    let isPopular: Bool
    let conversation: [ConversationPrompt]
}

struct ConversationPrompt {
    let prompt: String
    let suggestedResponses: [String]
}

struct TopicCategory: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    
    static let allCategories = [
        TopicCategory(name: "日常对话", icon: "bubble.left.and.bubble.right", color: AppColors.accent),
        TopicCategory(name: "商务英语", icon: "briefcase", color: AppColors.accent),
        TopicCategory(name: "旅行英语", icon: "airplane", color: AppColors.success),
        TopicCategory(name: "学术讨论", icon: "graduationcap", color: AppColors.accent),
        TopicCategory(name: "面试练习", icon: "person.badge.plus", color: AppColors.warning),
        TopicCategory(name: "生活服务", icon: "house", color: AppColors.success)
    ]
}

enum TopicDifficulty: String, CaseIterable {
    case beginner = "初级"
    case intermediate = "中级" 
    case advanced = "高级"
    
    var color: Color {
        switch self {
        case .beginner: return AppColors.success
        case .intermediate: return AppColors.warning
        case .advanced: return AppColors.destructive
        }
    }
}

// MARK: - Sample Data
extension PracticeTopic {
    static let sampleTopics = [
        // 日常对话
        PracticeTopic(
            title: "自我介绍",
            description: "练习用英语介绍自己，包括姓名、工作、兴趣爱好等",
            category: TopicCategory.allCategories[0],
            difficulty: .beginner,
            estimatedTime: 10,
            keywords: ["介绍", "姓名", "工作", "爱好"],
            icon: "person.circle",
            isPopular: true,
            conversation: [
                ConversationPrompt(
                    prompt: "请用英语介绍一下你自己",
                    suggestedResponses: ["Hi, I'm...", "My name is...", "I'd like to introduce myself..."]
                )
            ]
        ),
        
        PracticeTopic(
            title: "天气聊天",
            description: "学习如何用英语聊天气，这是日常对话中最常见的话题",
            category: TopicCategory.allCategories[0],
            difficulty: .beginner,
            estimatedTime: 8,
            keywords: ["天气", "温度", "晴天", "下雨"],
            icon: "cloud.sun",
            isPopular: true,
            conversation: [
                ConversationPrompt(
                    prompt: "今天天气怎么样？",
                    suggestedResponses: ["It's sunny today", "It's a bit cloudy", "It looks like it might rain"]
                )
            ]
        ),
        
        // 商务英语
        PracticeTopic(
            title: "商务会议",
            description: "练习商务会议中的英语表达，包括发言、提问、总结等",
            category: TopicCategory.allCategories[1],
            difficulty: .intermediate,
            estimatedTime: 20,
            keywords: ["会议", "发言", "提问", "总结"],
            icon: "person.3",
            isPopular: true,
            conversation: [
                ConversationPrompt(
                    prompt: "让我们开始今天的会议吧",
                    suggestedResponses: ["Let's get started", "Shall we begin?", "Good, let's start the meeting"]
                )
            ]
        ),
        
        PracticeTopic(
            title: "产品展示",
            description: "学习如何用英语展示产品特点和优势",
            category: TopicCategory.allCategories[1],
            difficulty: .advanced,
            estimatedTime: 25,
            keywords: ["产品", "展示", "特点", "优势"],
            icon: "display",
            isPopular: false,
            conversation: [
                ConversationPrompt(
                    prompt: "请介绍一下这个产品的主要特点",
                    suggestedResponses: ["This product features...", "The main advantage is...", "What makes it special is..."]
                )
            ]
        ),
        
        // 旅行英语
        PracticeTopic(
            title: "机场值机",
            description: "练习在机场值机时需要用到的英语对话",
            category: TopicCategory.allCategories[2],
            difficulty: .intermediate,
            estimatedTime: 15,
            keywords: ["机场", "值机", "行李", "座位"],
            icon: "airplane.departure",
            isPopular: true,
            conversation: [
                ConversationPrompt(
                    prompt: "我想办理值机手续",
                    suggestedResponses: ["I'd like to check in", "I need to check in for my flight", "I'm here for check-in"]
                )
            ]
        ),
        
        PracticeTopic(
            title: "酒店预订",
            description: "学习如何用英语预订酒店房间",
            category: TopicCategory.allCategories[2],
            difficulty: .beginner,
            estimatedTime: 12,
            keywords: ["酒店", "预订", "房间", "价格"],
            icon: "bed.double",
            isPopular: false,
            conversation: [
                ConversationPrompt(
                    prompt: "我想预订一个房间",
                    suggestedResponses: ["I'd like to book a room", "I need a reservation", "Do you have any rooms available?"]
                )
            ]
        ),
        
        // 学术讨论
        PracticeTopic(
            title: "学术演讲",
            description: "练习学术场合的英语演讲技巧",
            category: TopicCategory.allCategories[3],
            difficulty: .advanced,
            estimatedTime: 30,
            keywords: ["演讲", "学术", "研究", "结论"],
            icon: "person.wave.2",
            isPopular: false,
            conversation: [
                ConversationPrompt(
                    prompt: "请开始你的演讲",
                    suggestedResponses: ["Thank you for having me", "I'm pleased to present...", "Today I'll be discussing..."]
                )
            ]
        ),
        
        // 面试练习
        PracticeTopic(
            title: "工作面试",
            description: "练习英语工作面试中的常见问题和回答",
            category: TopicCategory.allCategories[4],
            difficulty: .intermediate,
            estimatedTime: 25,
            keywords: ["面试", "工作", "经验", "优势"],
            icon: "person.badge.plus",
            isPopular: true,
            conversation: [
                ConversationPrompt(
                    prompt: "请介绍一下你的工作经验",
                    suggestedResponses: ["I have experience in...", "In my previous role...", "I've been working as..."]
                )
            ]
        )
    ]
}


