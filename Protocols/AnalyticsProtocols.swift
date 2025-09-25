//
//  AnalyticsProtocols.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import Foundation

protocol AnalyticsServiceProtocol {
    func fetchLearningStats() async throws -> LearningStats
    func recordStudyTime(_ duration: TimeInterval) async throws
    func resetProgress() async throws
}

protocol DetailedAnalyticsService: AnalyticsServiceProtocol {
    func fetchDetailedStats() async throws -> DetailedLearningStats
    func fetchWeeklyProgress() async throws -> [DayProgress]
    func fetchMonthlyProgress() async throws -> [WeekProgress]
}
