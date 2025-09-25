//
//  speakingApp.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI

@main
struct speakingApp: App {
    let serviceContainer = ServiceContainer.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serviceContainer)
        }
    }
}
