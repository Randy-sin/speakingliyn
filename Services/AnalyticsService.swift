//
//  AnalyticsService.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import Foundation

// MARK: - Mock Analytics Service
class AnalyticsService: DetailedAnalyticsService {
    func fetchLearningStats() async throws -> LearningStats {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        return LearningStats(
            totalStudyTime: 20_880,
            conversationsCompleted: 15,
            wordsLearned: 120,
            pronunciationScore: 0.85,
            weeklyGoal: 25_200,
            currentStreak: 5
        )
    }
    
    func fetchDetailedStats() async throws -> DetailedLearningStats {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        return DetailedLearningStats(
            totalStudyTime: 20_880,
            conversationsCompleted: 15,
            wordsLearned: 120,
            pronunciationScore: 0.85,
            currentStreak: 5,
            longestStreak: 12,
            averageSessionTime: 1_392,
            totalSessions: 15,
            weeklyGoalProgress: 0.75
        )
    }
    
    func fetchWeeklyProgress() async throws -> [DayProgress] {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let calendar = Calendar.current
        let today = Date()
        var progress: [DayProgress] = []
        
        for i in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -6 + i, to: today)!
            let studyTime = Double.random(in: 0...3_600)
            let sessions = studyTime > 0 ? Int.random(in: 1...3) : 0
            progress.append(
                DayProgress(
                    date: date,
                    studyTime: studyTime,
                    sessions: sessions,
                    isCompleted: studyTime >= 1_800
                )
            )
        }
        
        return progress
    }
    
    func fetchMonthlyProgress() async throws -> [WeekProgress] {
        try await Task.sleep(nanoseconds: 500_000_000)
        
        let calendar = Calendar.current
        let today = Date()
        var progress: [WeekProgress] = []
        
        for i in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -3 + i, to: today)!
            let totalTime = Double.random(in: 7_200...25_200)
            let sessions = Int.random(in: 5...15)
            progress.append(
                WeekProgress(
                    weekStart: weekStart,
                    totalStudyTime: totalTime,
                    sessionsCount: sessions,
                    goalAchieved: totalTime >= 18_000
                )
            )
        }
        
        return progress
    }
    
    func recordStudyTime(_ duration: TimeInterval) async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
        print("记录学习时间：\(duration)秒")
    }
    
    func resetProgress() async throws {
        try await Task.sleep(nanoseconds: 300_000_000)
        print("重置学习进度")
    }
}
