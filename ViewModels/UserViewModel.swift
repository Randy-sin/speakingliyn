//
//  UserViewModel.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI
import Combine

@MainActor
class UserViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var user: User?
    @Published var learningStats: LearningStats?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private let userService: UserServiceProtocol
    private let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Init
    init(
        userService: UserServiceProtocol = UserService(),
        analyticsService: AnalyticsServiceProtocol = AnalyticsService()
    ) {
        self.userService = userService
        self.analyticsService = analyticsService
        loadUserProfile()
    }
    
    // MARK: - Public Methods
    func loadUserProfile() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let userData = try await userService.fetchUserData()
                let stats = try await analyticsService.fetchLearningStats()
                
                await MainActor.run {
                    // 创建用户对象
                    self.user = User(
                        id: UUID().uuidString,
                        name: "学习者",
                        email: "user@example.com",
                        level: .intermediate,
                        weeklyProgress: userData.weeklyProgress,
                        studyHours: userData.studyHours,
                        daysLeft: userData.daysLeft
                    )
                    self.learningStats = stats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载用户数据失败：\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    func updateProgress(studyTime: TimeInterval) {
        guard let currentUser = user else { return }
        
        Task {
            do {
                try await analyticsService.recordStudyTime(studyTime)
                
                // 更新本地用户数据
                await MainActor.run {
                    self.user = User(
                        id: currentUser.id,
                        name: currentUser.name,
                        email: currentUser.email,
                        level: currentUser.level,
                        weeklyProgress: min(currentUser.weeklyProgress + 0.1, 1.0),
                        studyHours: currentUser.studyHours + (studyTime / 3600),
                        daysLeft: max(currentUser.daysLeft - 1, 0)
                    )
                }
                
                // 重新加载统计数据
                loadUserProfile()
            } catch {
                await MainActor.run {
                    self.errorMessage = "更新进度失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    func resetProgress() {
        Task {
            do {
                try await analyticsService.resetProgress()
                loadUserProfile()
            } catch {
                await MainActor.run {
                    self.errorMessage = "重置进度失败：\(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    var progressPercentage: Int {
        guard let user = user else { return 0 }
        return Int(user.weeklyProgress * 100)
    }
    
    var formattedStudyHours: String {
        guard let user = user else { return "0.0" }
        return String(format: "%.1f", user.studyHours)
    }
    
    var formattedDaysLeft: String {
        guard let user = user else { return "0" }
        return "\(user.daysLeft)"
    }
}

// MARK: - User Model
struct User {
    let id: String
    let name: String
    let email: String
    let level: LanguageLevel
    let weeklyProgress: Double
    let studyHours: Double
    let daysLeft: Int
}

// MARK: - Language Level Enum
enum LanguageLevel: String, CaseIterable {
    case beginner = "初级"
    case intermediate = "中级"
    case advanced = "高级"
    case native = "母语水平"
}

