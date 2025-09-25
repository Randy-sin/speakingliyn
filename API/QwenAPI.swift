//
//  QwenAPI.swift
//  speaking
//
//  Created by Randy on 25/9/2025.
//

import Foundation

struct QwenRequest: Encodable {
    let model: String
    let messages: [QwenMessage]
    let stream: Bool
    let streamOptions: StreamOptions?
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case stream
        case streamOptions = "stream_options"
    }
}

struct QwenMessage: Encodable {
    let role: String
    let content: String
}

struct StreamOptions: Encodable {
    let includeUsage: Bool
    
    enum CodingKeys: String, CodingKey {
        case includeUsage = "include_usage"
    }
}

struct QwenResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}

enum QwenSecrets {
    static let apiKey = "sk-c82d31a8108b470b9dc5b351cad3334e"
}

protocol QwenServiceProtocol {
    func sendChat(messages: [QwenMessage]) async throws -> String
}

final class QwenService: QwenServiceProtocol {
    private let session: URLSession
    private let baseURL = URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")!
    private let apiKey: String
    
    init(session: URLSession = .shared, apiKey: String = QwenSecrets.apiKey) {
        self.session = session
        self.apiKey = apiKey
    }
    
    func sendChat(messages: [QwenMessage]) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "QwenService", code: -1, userInfo: [NSLocalizedDescriptionKey: "缺少 Qwen API Key"]) }
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let body = QwenRequest(
            model: "qwen-flash-2025-07-28",
            messages: messages,
            stream: false,
            streamOptions: nil
        )
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        let httpResponse = response as? HTTPURLResponse
        guard let status = httpResponse?.statusCode, 200..<300 ~= status else {
            let message = String(data: data, encoding: .utf8) ?? "未知错误"
            throw NSError(domain: "QwenService", code: httpResponse?.statusCode ?? -999, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        let result = try JSONDecoder().decode(QwenResponse.self, from: data)
        guard let content = result.choices.first?.message.content else {
            throw NSError(domain: "QwenService", code: -2, userInfo: [NSLocalizedDescriptionKey: "未返回内容"])
        }
        return content
    }
}
