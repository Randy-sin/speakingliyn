//
//  ServiceContainer.swift
//  speaking
//
//  Created by Randy on 25/9/2025.
//

import Foundation
import SwiftUI

@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    // 单例服务
    lazy var userService: UserServiceProtocol = UserService()
    lazy var aiService: AIServiceProtocol = QwenChatService()
    lazy var audioPlayerService: AudioServiceProtocol = AudioService()
    lazy var fileUploadService: FileUploadServiceProtocol = FileUploadService()
    lazy var asrService: QwenASRServiceProtocol = QwenASRService(fileUploadService: fileUploadService)
    lazy var streamingASRService: StreamingASRServiceProtocol = StreamingASRService(asrService: asrService, fileUploadService: fileUploadService)
    lazy var analyticsService: AnalyticsServiceProtocol = AnalyticsService()
    
    private init() {}
    
    // ViewModel工厂方法
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(userService: userService)
    }
    
    func makeChatViewModel() -> ChatViewModel {
        ChatViewModel(
            aiService: aiService,
            audioPlayerService: audioPlayerService,
            streamingASRService: streamingASRService
        )
    }
    
    func makeUserViewModel() -> UserViewModel {
        UserViewModel(userService: userService, analyticsService: analyticsService)
    }
}

// MARK: - Environment注入
extension EnvironmentValues {
    private struct ServiceContainerKey: EnvironmentKey {
        static let defaultValue = ServiceContainer.shared
    }
    
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
