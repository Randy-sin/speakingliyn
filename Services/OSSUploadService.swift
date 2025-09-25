//
//  OSSUploadService.swift
//  speaking
//
//  Created by Randy on 25/9/2025.
//

import Foundation

protocol OSSUploadServiceProtocol {
    func uploadAudio(_ audioData: Data, fileName: String) async throws -> URL
}

final class OSSUploadService: OSSUploadServiceProtocol {
    private let session: URLSession
    private let bucketName = "your-bucket-name" // 需要配置你的OSS bucket
    private let region = "oss-cn-hangzhou" // 需要配置你的region
    private let accessKeyId = "your-access-key-id" // 需要配置
    private let accessKeySecret = "your-access-key-secret" // 需要配置
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func uploadAudio(_ audioData: Data, fileName: String) async throws -> URL {
        // TODO: 实现OSS上传逻辑
        // 1. 生成签名
        // 2. 构造PUT请求
        // 3. 上传文件
        // 4. 返回公网URL
        
        throw NSError(domain: "OSSUploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "OSS配置待完成"])
    }
}
