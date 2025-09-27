//
//  SearchBar.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.tertiary)
                .font(.system(size: 16, weight: .light))
            
            TextField(placeholder, text: $text)
                .font(AppFonts.callout)
                .foregroundColor(AppColors.primary)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.surface)
        .cornerRadius(AppRadius.md)
        .shadow(color: AppShadow.subtle, radius: 12, x: 0, y: 6)
    }
}

#Preview {
    @Previewable @State var searchText = ""
    return SearchBar(text: $searchText, placeholder: "搜索单词、短语或句子...")
        .padding()
        .background(AppColors.background)
}
