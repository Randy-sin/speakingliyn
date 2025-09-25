//
//  DesignSystem.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

// MARK: - 硅谷风格颜色系统
struct AppColors {
    // 主色调 - 柔和浅色系
    static let primary = Color(red: 0.12, green: 0.16, blue: 0.24)
    static let secondary = Color(red: 0.43, green: 0.47, blue: 0.55)
    static let tertiary = Color(red: 0.70, green: 0.73, blue: 0.78)
    
    // 背景色
    static let background = Color(red: 0.97, green: 0.98, blue: 1.0)
    static let secondaryBackground = Color(red: 0.94, green: 0.96, blue: 0.99)
    static let groupedBackground = Color(red: 0.97, green: 0.98, blue: 1.0)
    static let surface = Color.white
    
    // 功能色 - 柔和蓝紫系
    static let accent = Color(red: 0.32, green: 0.45, blue: 0.98)
    static let success = Color(red: 0.36, green: 0.70, blue: 0.47)
    static let warning = Color(red: 0.98, green: 0.72, blue: 0.36)
    static let destructive = Color(red: 0.94, green: 0.44, blue: 0.41)
    
    // 卡片和组件
    static let cardBackground = Color.white
    static let cardBorder = Color(red: 0.89, green: 0.91, blue: 0.95)
    
    // 渐变
    static let gradientStart = Color(red: 0.82, green: 0.88, blue: 1.0)
    static let gradientEnd = Color(red: 0.70, green: 0.80, blue: 0.99)
    static let subtleGradientStart = Color(red: 0.96, green: 0.97, blue: 1.0)
    static let subtleGradientEnd = Color(red: 0.93, green: 0.95, blue: 1.0)
    
    // 语音界面渐变
    static let voiceGradientStart = Color(red: 0.91, green: 0.93, blue: 1.0)
    static let voiceGradientEnd = Color(red: 0.98, green: 0.92, blue: 0.99)
}

// MARK: - 字体系统
struct AppFonts {
    // 标题
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    // 正文
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
}

// MARK: - 间距系统
struct AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 40
}

// MARK: - 圆角系统
struct AppRadius {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let full: CGFloat = 999
}

// MARK: - 阴影系统
struct AppShadow {
    static let subtle = Color.black.opacity(0.04)
    static let light = Color.black.opacity(0.06)
    static let medium = Color.black.opacity(0.1)
    static let strong = Color.black.opacity(0.14)
}


