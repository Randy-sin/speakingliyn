//
//  FileUploadService.swift
//  speaking
//
//  Created by Randy on 25/9/2025.
//

import Foundation

protocol FileUploadServiceProtocol {
    func uploadAudio(_ audioData: Data, fileName: String) async throws -> URL
}

final class FileUploadService: FileUploadServiceProtocol {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func uploadAudio(_ audioData: Data, fileName: String) async throws -> URL {
        // 使用 0x0.st 临时文件上传服务（免费，支持音频）
        let uploadURL = URL(string: "https://0x0.st")!
        
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        
        // 构造 multipart/form-data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // 添加文件数据
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/m4a\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        print("[Upload] Uploading \(audioData.count) bytes to 0x0.st")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            let message = String(data: data, encoding: .utf8) ?? "上传失败"
            throw NSError(domain: "FileUploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        }
        
        guard let urlString = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let fileURL = URL(string: urlString) else {
            throw NSError(domain: "FileUploadService", code: -2, userInfo: [NSLocalizedDescriptionKey: "无法解析上传响应"])
        }
        
        print("[Upload] File uploaded to: \(fileURL.absoluteString)")
        return fileURL
    }
}
