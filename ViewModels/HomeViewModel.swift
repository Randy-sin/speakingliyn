//
//  HomeViewModel.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI
import Combine

@MainActor
class HomeViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText = ""
    @Published var showChatView = false
    @Published var learningProgress: Double = 0.75
    @Published var studyHours = "5.8"
    @Published var daysLeft = "1"
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private let userService: UserServiceProtocol
    
    // MARK: - Init
    init(userService: UserServiceProtocol = UserService()) {
        self.userService = userService
        setupBindings()
        loadUserData()
    }
    
    // MARK: - Public Methods
    func startConversation() {
        showChatView = true
    }
    
    func startWordPractice() {
        // TODO: 实现背单词功能
        print("开始背单词练习")
    }
    
    func startSpeakingPractice() {
        // TODO: 实现跟读练习功能
        print("开始跟读练习")
    }
    
    func startWritingCorrection() {
        // TODO: 实现作文批改功能
        print("开始作文批改")
    }
    
    func startRecommendedPractice() {
        showChatView = true
    }
    
    func switchWordLibrary() {
        // TODO: 实现切换词库功能
        print("切换词库")
    }
    
    func refreshData() {
        loadUserData()
    }
    
    // MARK: - Private Methods
    private func setupBindings() {
        // 监听搜索文本变化
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.performSearch(searchText)
            }
            .store(in: &cancellables)
    }
    
    private func loadUserData() {
        isLoading = true
        errorMessage = nil
        
        // 模拟网络请求
        Task {
            do {
                let userData = try await userService.fetchUserData()
                await MainActor.run {
                    self.learningProgress = userData.weeklyProgress
                    self.studyHours = String(format: "%.1f", userData.studyHours)
                    self.daysLeft = "\(userData.daysLeft)"
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载数据失败：\(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func performSearch(_ searchText: String) {
        guard !searchText.isEmpty else { return }
        
        // TODO: 实现搜索功能
        print("搜索：\(searchText)")
    }
}

// MARK: - User Data Model
struct UserData {
    let weeklyProgress: Double
    let studyHours: Double
    let daysLeft: Int
}

// MARK: - User Service Protocol
protocol UserServiceProtocol {
    func fetchUserData() async throws -> UserData
}

// MARK: - User Service Implementation
class UserService: UserServiceProtocol {
    func fetchUserData() async throws -> UserData {
        // 模拟网络延迟
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // 模拟数据
        return UserData(
            weeklyProgress: 0.75,
            studyHours: 5.8,
            daysLeft: 1
        )
    }
}

