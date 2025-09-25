//
//  QwenASRService.swift
//  speaking
//
//  Created by Randy on 25/9/2025.
//

import Foundation

private struct QwenASRRequest: Encodable {
    let model: String
    let messages: [ASRMessage]
    let resultFormat: String
    let asrOptions: ASROptions
    
    enum CodingKeys: String, CodingKey {
        case model, messages
        case resultFormat = "result_format"
        case asrOptions = "asr_options"
    }
}

private struct ASRMessage: Encodable {
    let role: String
    let content: [ASRContent]
}

private struct ASRContent: Encodable {
    let text: String?
    let audio: String?
    
    init(text: String) {
        self.text = text
        self.audio = nil
    }
    
    init(audioURL: String) {
        self.text = nil
        self.audio = audioURL
    }
}

private struct ASROptions: Encodable {
    let enableLid: Bool
    let enableItn: Bool
    let language: String?
    
    enum CodingKeys: String, CodingKey {
        case enableLid = "enable_lid"
        case enableItn = "enable_itn"
        case language
    }
}

protocol QwenASRServiceProtocol {
    func transcribe(audioURL url: URL, language: String?) async throws -> String
}

final class QwenASRService: QwenASRServiceProtocol {
    private let session: URLSession
    private let baseURL = URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1/multimodal-conversation")!
    private let apiKey: String
    private let fileUploadService: FileUploadServiceProtocol
    
    init(session: URLSession = .shared, apiKey: String = QwenSecrets.apiKey, fileUploadService: FileUploadServiceProtocol = FileUploadService()) {
        self.session = session
        self.apiKey = apiKey
        self.fileUploadService = fileUploadService
    }
    
    func transcribe(audioURL url: URL, language: String?) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "QwenASRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "缺少 Qwen API Key"])
        }
        
        // 读取音频文件
        let audioData = try Data(contentsOf: url)
        let fileName = "voice_\(UUID().uuidString).m4a"
        
        print("[ASR] Uploading audio file: \(audioData.count) bytes")
        
        // 上传音频文件获取公网URL
        let publicURL = try await fileUploadService.uploadAudio(audioData, fileName: fileName)
        
        print("[ASR] Public URL: \(publicURL.absoluteString)")
        
        // 构造请求体，严格按照官方文档格式
        let requestBody = QwenASRRequest(
            model: "qwen3-asr-flash",
            messages: [
                ASRMessage(role: "system", content: [ASRContent(text: "")]),
                ASRMessage(role: "user", content: [ASRContent(audioURL: publicURL.absoluteString)])
            ],
            resultFormat: "message",
            asrOptions: ASROptions(
                enableLid: language == nil,
                enableItn: false,
                language: language
            )
        )
        
        // 编码并打印请求体用于调试
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let requestData = try encoder.encode(requestBody)
        let requestString = String(data: requestData, encoding: .utf8) ?? "无法编码请求体"
        print("[ASR] Request Body:\n\(requestString)")
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "QwenASRService", code: -2, userInfo: [NSLocalizedDescriptionKey: "无效的响应"])
        }
        
        print("[ASR] status: \(httpResponse.statusCode)")
        
        guard 200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "未知错误"
            print("[ASR][Error] Response body: \(message)")
            throw NSError(domain: "QwenASRService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        // 解析响应
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(domain: "QwenASRService", code: -3, userInfo: [NSLocalizedDescriptionKey: "无法解析 JSON 响应"])
        }
        
        print("[ASR] Full response: \(json)")
        
        // 尝试多种可能的响应格式
        if let output = json["output"] as? [String: Any],
           let choices = output["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? [[String: Any]] {
            
            for item in content {
                if let text = item["text"] as? String, !text.isEmpty {
                    return text
                }
            }
        }
        
        // 备用解析方式
        if let output = json["output"] as? [String: Any],
           let text = output["text"] as? String {
            return text
        }
        
        throw NSError(domain: "QwenASRService", code: -4, userInfo: [NSLocalizedDescriptionKey: "无法从响应中提取识别文本"])
    }
}
