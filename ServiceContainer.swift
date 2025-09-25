//
//  ServiceContainer.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import Foundation
import SwiftUI

// MARK: - Service Container
@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // MARK: - Services
    lazy var userService: UserServiceProtocol = UserService()
    lazy var aiService: AIServiceProtocol = QwenChatService()
    lazy var audioPlayerService: AudioServiceProtocol = AudioService()
    lazy var fileUploadService: FileUploadServiceProtocol = FileUploadService()
    lazy var asrService: QwenASRServiceProtocol = QwenASRService(fileUploadService: fileUploadService)
    lazy var recorderService: AudioRecorderServiceProtocol = AudioRecorderService()
    lazy var analyticsService: AnalyticsServiceProtocol = AnalyticsService()
    
    private init() {}
    
    // MARK: - Factory Methods
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(userService: userService)
    }
    
    func makeChatViewModel() -> ChatViewModel {
        ChatViewModel(
            aiService: aiService,
            audioPlayerService: audioPlayerService,
            asrService: asrService,
            recorderService: recorderService
        )
    }
    
    func makeUserViewModel() -> UserViewModel {
        UserViewModel(userService: userService, analyticsService: analyticsService)
    }
}

// MARK: - Environment Key
struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

// MARK: - Environment Values Extension
extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
