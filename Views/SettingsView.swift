//
//  SettingsView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        NavigationView {
            List {
                // 学习设置
                learningSettingsSection
                
                // 通知设置
                notificationSettingsSection
                
                // 语音设置
                voiceSettingsSection
                
                // 应用设置
                appSettingsSection
                
                // 数据和隐私
                dataAndPrivacySection
                
                // 关于
                aboutSection
            }
            .listStyle(InsetGroupedListStyle())
            .background(AppColors.groupedBackground)
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("重置设置", isPresented: $viewModel.showingResetAlert) {
            Button("取消", role: .cancel) { }
            Button("重置", role: .destructive) {
                viewModel.resetAllSettings()
            }
        } message: {
            Text("这将重置所有设置到默认值，此操作无法撤销。")
        }
        .sheet(isPresented: $viewModel.showingAbout) {
            AboutView()
        }
    }
    
    // MARK: - 学习设置
    private var learningSettingsSection: some View {
        Section("学习设置") {
            // 每日目标
            HStack {
                SettingsRowIcon(icon: "target", color: AppColors.accent)
                
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Text("每日目标")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.primary)
                    
                    Text("\(viewModel.dailyGoalMinutes)分钟")
                        .font(AppFonts.caption1)
                        .foregroundColor(AppColors.secondary)
                }
                
                Spacer()
                
                Stepper(
                    "",
                    value: $viewModel.dailyGoalMinutes,
                    in: 10...120,
                    step: 10
                )
            }
            .padding(.vertical, AppSpacing.xs)
            
            // 语言水平
            NavigationLink(destination: LanguageLevelPicker(selectedLevel: $viewModel.selectedLanguageLevel)) {
                HStack {
                    SettingsRowIcon(icon: "graduationcap", color: AppColors.success)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("语言水平")
                            .font(AppFonts.callout)
                            .foregroundColor(AppColors.primary)
                        
                        Text(viewModel.selectedLanguageLevel.rawValue)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
    }
    
    // MARK: - 通知设置
    private var notificationSettingsSection: some View {
        Section("通知设置") {
            // 启用通知
            HStack {
                SettingsRowIcon(icon: "bell", color: AppColors.warning)
                
                Text("学习提醒")
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isNotificationEnabled)
                    .tint(AppColors.accent)
            }
            .padding(.vertical, AppSpacing.xs)
            
            // 提醒时间
            if viewModel.isNotificationEnabled {
                HStack {
                    SettingsRowIcon(icon: "clock", color: AppColors.accent)
                    
                    Text("提醒时间")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    DatePicker(
                        "",
                        selection: $viewModel.reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
    }
    
    // MARK: - 语音设置
    private var voiceSettingsSection: some View {
        Section("语音设置") {
            // 语音速度
            NavigationLink(destination: VoiceSpeedPicker(selectedSpeed: $viewModel.selectedVoiceSpeed)) {
                HStack {
                    SettingsRowIcon(icon: "waveform", color: AppColors.accent)
                    
                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text("语音速度")
                            .font(AppFonts.callout)
                            .foregroundColor(AppColors.primary)
                        
                        Text(viewModel.selectedVoiceSpeed.rawValue)
                            .font(AppFonts.caption1)
                            .foregroundColor(AppColors.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, AppSpacing.xs)
            }
            
            // 自动播放
            HStack {
                SettingsRowIcon(icon: "play.circle", color: AppColors.success)
                
                Text("自动播放回复")
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isAutoPlayEnabled)
                    .tint(AppColors.accent)
            }
            .padding(.vertical, AppSpacing.xs)
        }
    }
    
    // MARK: - 应用设置
    private var appSettingsSection: some View {
        Section("应用设置") {
            // 深色模式
            HStack {
                SettingsRowIcon(icon: "moon", color: AppColors.secondary)
                
                Text("深色模式")
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.primary)
                
                Spacer()
                
                Toggle("", isOn: $viewModel.isDarkModeEnabled)
                    .tint(AppColors.accent)
            }
            .padding(.vertical, AppSpacing.xs)
        }
    }
    
    // MARK: - 数据和隐私
    private var dataAndPrivacySection: some View {
        Section("数据和隐私") {
            // 导出数据
            Button(action: viewModel.exportLearningData) {
                HStack {
                    SettingsRowIcon(icon: "square.and.arrow.up", color: AppColors.accent)
                    
                    Text("导出学习数据")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.tertiary)
                }
                .padding(.vertical, AppSpacing.xs)
            }
            
            // 重置设置
            Button(action: { viewModel.showingResetAlert = true }) {
                HStack {
                    SettingsRowIcon(icon: "arrow.clockwise", color: AppColors.destructive)
                    
                    Text("重置所有设置")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.destructive)
                    
                    Spacer()
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
    }
    
    // MARK: - 关于
    private var aboutSection: some View {
        Section("关于") {
            Button(action: viewModel.showAboutPage) {
                HStack {
                    SettingsRowIcon(icon: "info.circle", color: AppColors.accent)
                    
                    Text("关于Speaking")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.tertiary)
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
    }
}

// MARK: - Settings Row Icon
struct SettingsRowIcon: View {
    let icon: String
    let color: Color
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(color)
            .frame(width: 28, height: 28)
            .background(color.opacity(0.1))
            .cornerRadius(AppRadius.xs)
    }
}

// MARK: - Language Level Picker
struct LanguageLevelPicker: View {
    @Binding var selectedLevel: LanguageLevel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(LanguageLevel.allCases, id: \.self) { level in
                HStack {
                    Text(level.rawValue)
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    if selectedLevel == level {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedLevel = level
                    dismiss()
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
        .navigationTitle("语言水平")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Voice Speed Picker
struct VoiceSpeedPicker: View {
    @Binding var selectedSpeed: VoiceSpeed
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            ForEach(VoiceSpeed.allCases, id: \.self) { speed in
                HStack {
                    Text(speed.rawValue)
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.primary)
                    
                    Spacer()
                    
                    if selectedSpeed == speed {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSpeed = speed
                    dismiss()
                }
                .padding(.vertical, AppSpacing.xs)
            }
        }
        .navigationTitle("语音速度")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppSpacing.xl) {
                Spacer()
                
                // App图标
                Image(systemName: "waveform")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundColor(AppColors.accent)
                
                VStack(spacing: AppSpacing.sm) {
                    Text("Speaking")
                        .font(AppFonts.largeTitle)
                        .foregroundColor(AppColors.primary)
                    
                    Text("AI口语助手")
                        .font(AppFonts.title3)
                        .foregroundColor(AppColors.secondary)
                    
                    Text("版本 1.0.0")
                        .font(AppFonts.callout)
                        .foregroundColor(AppColors.tertiary)
                }
                
                Text("让AI成为你最好的口语练习伙伴")
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                
                Spacer()
                
                Text("© 2025 Speaking Team")
                    .font(AppFonts.caption1)
                    .foregroundColor(AppColors.tertiary)
            }
            .padding(AppSpacing.xl)
            .background(AppColors.background)
            .navigationTitle("关于")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(AppFonts.callout)
                    .foregroundColor(AppColors.accent)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}


