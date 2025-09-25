//
//  StatsViewModel.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

@MainActor
class StatsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var learningStats: DetailedLearningStats?
    @Published var weeklyProgress: [DayProgress] = []
    @Published var monthlyProgress: [WeekProgress] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTimeRange: TimeRange = .week
    
    // MARK: - Properties
    private let analyticsService: DetailedAnalyticsService
    
    // MARK: - Init
    init(analyticsService: DetailedAnalyticsService = AnalyticsService()) {
        self.analyticsService = analyticsService
        loadStats()
    }
    
    // MARK: - Public Methods
    func loadStats() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let stats = try await analyticsService.fetchDetailedStats()
                let weeklyData = try await analyticsService.fetchWeeklyProgress()
                let monthlyData = try await analyticsService.fetchMonthlyProgress()
                
                await MainActor.run {
                    self.learningStats = stats
                    self.weeklyProgress = weeklyData
                    self.monthlyProgress = monthlyData
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载统计数据失败：\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func changeTimeRange(_ range: TimeRange) {
        selectedTimeRange = range
        loadStats()
    }
    
    // MARK: - Computed Properties
    var totalStudyTimeFormatted: String {
        guard let stats = learningStats else { return "0小时" }
        let hours = Int(stats.totalStudyTime / 3600)
        let minutes = Int((stats.totalStudyTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return hours > 0 ? "\(hours)小时\(minutes)分钟" : "\(minutes)分钟"
    }
    
    var currentStreakText: String {
        guard let stats = learningStats else { return "0天" }
        return "\(stats.currentStreak)天"
    }
    
    var pronunciationScorePercentage: Int {
        guard let stats = learningStats else { return 0 }
        return Int(stats.pronunciationScore * 100)
    }
}

// MARK: - Models
struct DetailedLearningStats {
    let totalStudyTime: TimeInterval
    let conversationsCompleted: Int
    let wordsLearned: Int
    let pronunciationScore: Double
    let currentStreak: Int
    let longestStreak: Int
    let averageSessionTime: TimeInterval
    let totalSessions: Int
    let weeklyGoalProgress: Double
}

struct DayProgress {
    let date: Date
    let studyTime: TimeInterval
    let sessions: Int
    let isCompleted: Bool
}

struct WeekProgress {
    let weekStart: Date
    let totalStudyTime: TimeInterval
    let sessionsCount: Int
    let goalAchieved: Bool
}

enum TimeRange: String, CaseIterable {
    case week = "本周"
    case month = "本月"
    case year = "今年"
}


