//
//  Message.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import Foundation

struct Message: Identifiable, Codable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    let audioURL: URL?
    
    init(text: String, isFromUser: Bool, audioURL: URL? = nil) {
        self.id = UUID()
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = Date()
        self.audioURL = audioURL
    }
}

// MARK: - 会话模型
struct Conversation: Identifiable, Codable {
    let id: UUID
    let title: String
    let messages: [Message]
    let createdAt: Date
    let lastUpdated: Date
    
    init(title: String, messages: [Message] = []) {
        self.id = UUID()
        self.title = title
        self.messages = messages
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
}


