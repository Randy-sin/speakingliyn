//
//  MainTabView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("首页")
                }
                .tag(0)
            
            TopicsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "text.book.closed.fill" : "text.book.closed")
                    Text("话题")
                }
                .tag(1)
            
            StatsView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.bar.fill" : "chart.bar")
                    Text("统计")
                }
                .tag(2)
        }
        .accentColor(AppColors.accent)
        .preferredColorScheme(.light)
        .background(AppColors.background.ignoresSafeArea())
    }
}

#Preview {
    MainTabView()
}
