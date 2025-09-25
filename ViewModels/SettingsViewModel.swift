//
//  SettingsViewModel.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var dailyGoalMinutes: Int = 30
    @Published var isNotificationEnabled: Bool = true
    @Published var reminderTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
    @Published var selectedVoiceSpeed: VoiceSpeed = .normal
    @Published var isAutoPlayEnabled: Bool = true
    @Published var selectedLanguageLevel: LanguageLevel = .intermediate
    @Published var isDarkModeEnabled: Bool = false
    @Published var isLoading = false
    @Published var showingResetAlert = false
    @Published var showingAbout = false
    
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        loadSettings()
        setupBindings()
    }
    
    // MARK: - Public Methods
    func saveSettings() {
        // 保存设置到UserDefaults或服务器
        UserDefaults.standard.set(dailyGoalMinutes, forKey: "dailyGoalMinutes")
        UserDefaults.standard.set(isNotificationEnabled, forKey: "isNotificationEnabled")
        UserDefaults.standard.set(reminderTime, forKey: "reminderTime")
        UserDefaults.standard.set(selectedVoiceSpeed.rawValue, forKey: "selectedVoiceSpeed")
        UserDefaults.standard.set(isAutoPlayEnabled, forKey: "isAutoPlayEnabled")
        UserDefaults.standard.set(selectedLanguageLevel.rawValue, forKey: "selectedLanguageLevel")
        UserDefaults.standard.set(isDarkModeEnabled, forKey: "isDarkModeEnabled")
        
        // 更新通知设置
        if isNotificationEnabled {
            scheduleNotifications()
        } else {
            cancelNotifications()
        }
    }
    
    func resetAllSettings() {
        dailyGoalMinutes = 30
        isNotificationEnabled = true
        reminderTime = Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        selectedVoiceSpeed = .normal
        isAutoPlayEnabled = true
        selectedLanguageLevel = .intermediate
        isDarkModeEnabled = false
        
        saveSettings()
    }
    
    func exportLearningData() {
        // 导出学习数据
        print("导出学习数据")
    }
    
    func showAboutPage() {
        showingAbout = true
    }
    
    // MARK: - Private Methods
    private func loadSettings() {
        dailyGoalMinutes = UserDefaults.standard.object(forKey: "dailyGoalMinutes") as? Int ?? 30
        isNotificationEnabled = UserDefaults.standard.object(forKey: "isNotificationEnabled") as? Bool ?? true
        reminderTime = UserDefaults.standard.object(forKey: "reminderTime") as? Date ?? 
            Calendar.current.date(from: DateComponents(hour: 20, minute: 0)) ?? Date()
        
        if let speedRawValue = UserDefaults.standard.object(forKey: "selectedVoiceSpeed") as? String {
            selectedVoiceSpeed = VoiceSpeed(rawValue: speedRawValue) ?? .normal
        }
        
        isAutoPlayEnabled = UserDefaults.standard.object(forKey: "isAutoPlayEnabled") as? Bool ?? true
        
        if let levelRawValue = UserDefaults.standard.object(forKey: "selectedLanguageLevel") as? String {
            selectedLanguageLevel = LanguageLevel(rawValue: levelRawValue) ?? .intermediate
        }
        
        isDarkModeEnabled = UserDefaults.standard.object(forKey: "isDarkModeEnabled") as? Bool ?? false
    }
    
    private func setupBindings() {
        // 监听设置变化并自动保存
        Publishers.CombineLatest4(
            $dailyGoalMinutes,
            $isNotificationEnabled,
            $selectedVoiceSpeed,
            $isAutoPlayEnabled
        )
        .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
        .sink { [weak self] _, _, _, _ in
            self?.saveSettings()
        }
        .store(in: &cancellables)
    }
    
    private func scheduleNotifications() {
        // 实现推送通知调度
        print("调度推送通知在 \(reminderTime)")
    }
    
    private func cancelNotifications() {
        // 取消推送通知
        print("取消推送通知")
    }
}

// MARK: - Models
enum VoiceSpeed: String, CaseIterable {
    case slow = "慢速"
    case normal = "正常"
    case fast = "快速"
}

// MARK: - Settings Data
struct SettingsSection {
    let title: String
    let items: [SettingsItem]
}

struct SettingsItem {
    let title: String
    let subtitle: String?
    let icon: String
    let action: SettingsAction
}

enum SettingsAction {
    case toggle(Binding<Bool>)
    case navigation(() -> Void)
    case picker
    case timePicker
    case destructive(() -> Void)
}


