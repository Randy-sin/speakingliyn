//
//  FunASRService.swift
//  speaking
//
//  Created by Randy on 25/9/2025.
//

import Foundation
import AVFoundation

// MARK: - 请求/响应模型
private struct FunASRRequest: Encodable {
    let model: String
    let parameters: FunASRParameters
}

private struct FunASRParameters: Encodable {
    let sampleRate: Int
    let format: String
    let semanticPunctuationEnabled: Bool
    let maxSentenceSilence: Int
    let multiThresholdModeEnabled: Bool
    let punctuationPredictionEnabled: Bool
    let heartbeat: Bool
    
    enum CodingKeys: String, CodingKey {
        case sampleRate = "sample_rate"
        case format
        case semanticPunctuationEnabled = "semantic_punctuation_enabled"
        case maxSentenceSilence = "max_sentence_silence"
        case multiThresholdModeEnabled = "multi_threshold_mode_enabled"
        case punctuationPredictionEnabled = "punctuation_prediction_enabled"
        case heartbeat
    }
}

private struct FunASRResponse: Decodable {
    let output: FunASROutput?
    let usage: Usage?
    let requestId: String
    
    enum CodingKeys: String, CodingKey {
        case output, usage
        case requestId = "request_id"
    }
}

private struct FunASROutput: Decodable {
    let sentence: SentenceInfo?
}

private struct SentenceInfo: Decodable {
    let beginTime: Int
    let endTime: Int
    let text: String
    let words: [WordInfo]
    
    enum CodingKeys: String, CodingKey {
        case beginTime = "begin_time"
        case endTime = "end_time"
        case text, words
    }
}

private struct WordInfo: Decodable {
    let beginTime: Int
    let endTime: Int
    let text: String
    let punctuation: String
    
    enum CodingKeys: String, CodingKey {
        case beginTime = "begin_time"
        case endTime = "end_time"
        case text, punctuation
    }
}

private struct Usage: Decodable {
    let seconds: Int
}

// MARK: - 协议定义
protocol FunASRServiceProtocol {
    func startStreaming() async throws
    func sendAudioFrame(_ audioData: Data) async throws
    func stopStreaming() async throws
    
    var onPartialResult: ((String) -> Void)? { get set }
    var onFinalResult: ((String) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
}

// MARK: - Fun-ASR流式识别服务
final class FunASRService: FunASRServiceProtocol {
    private let session: URLSession
    private let baseURL = URL(string: "https://dashscope.aliyuncs.com/api/v1/services/aigc/asr/transcription")!
    private let apiKey: String
    
    // 回调闭包
    var onPartialResult: ((String) -> Void)?
    var onFinalResult: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    // 状态管理
    private var isStreaming = false
    private var currentTask: URLSessionDataTask?
    private var partialText = ""
    private var silenceTimer: Timer?
    private let maxSilenceDuration: TimeInterval = 2.5 // 2.5秒静音判断句子结束
    
    init(session: URLSession = .shared, apiKey: String = QwenSecrets.apiKey) {
        self.session = session
        self.apiKey = apiKey
    }
    
    func startStreaming() async throws {
        guard !isStreaming else { return }
        isStreaming = true
        partialText = ""
        
        print("[FunASR] 开始流式识别")
        
        // 构建请求
        let requestBody = FunASRRequest(
            model: "fun-asr-realtime",
            parameters: FunASRParameters(
                sampleRate: 16000,
                format: "pcm",
                semanticPunctuationEnabled: false,  // 使用VAD断句
                maxSentenceSilence: 2500,           // 2.5秒静音阈值
                multiThresholdModeEnabled: true,    // 防止过长切割
                punctuationPredictionEnabled: true, // 自动添加标点
                heartbeat: true                     // 保持长连接
            )
        )
        
        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // 启动流式连接
        currentTask = session.dataTask(with: request) { [weak self] data, response, error in
            self?.handleStreamingResponse(data: data, response: response, error: error)
        }
        
        currentTask?.resume()
    }
    
    func sendAudioFrame(_ audioData: Data) async throws {
        guard isStreaming else {
            throw NSError(domain: "FunASRService", code: -1, userInfo: [NSLocalizedDescriptionKey: "流式识别未启动"])
        }
        
        // 重置静音计时器
        await MainActor.run {
            self.silenceTimer?.invalidate()
            self.silenceTimer = Timer.scheduledTimer(withTimeInterval: maxSilenceDuration, repeats: false) { [weak self] _ in
                Task {
                    await self?.handleSilenceTimeout()
                }
            }
        }
        
        // 发送音频数据（这里需要实现具体的数据传输逻辑）
        // Fun-ASR的流式API可能需要WebSocket或特定的数据流格式
        print("[FunASR] 发送音频帧: \(audioData.count) bytes")
    }
    
    func stopStreaming() async throws {
        guard isStreaming else { return }
        
        isStreaming = false
        currentTask?.cancel()
        currentTask = nil
        
        await MainActor.run {
            self.silenceTimer?.invalidate()
            self.silenceTimer = nil
        }
        
        print("[FunASR] 停止流式识别")
    }
    
    // MARK: - 私有方法
    
    private func handleStreamingResponse(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            print("[FunASR][Error] 流式响应错误: \(error)")
            onError?(error)
            return
        }
        
        guard let data = data else { return }
        
        do {
            let response = try JSONDecoder().decode(FunASRResponse.self, from: data)
            
            if let sentence = response.output?.sentence {
                let text = sentence.text
                
                // 判断是否为部分结果还是最终结果
                if isSentenceComplete(sentence) {
                    print("[FunASR] 最终结果: \(text)")
                    onFinalResult?(text)
                    partialText = ""
                } else {
                    print("[FunASR] 部分结果: \(text)")
                    partialText = text
                    onPartialResult?(text)
                }
            }
        } catch {
            print("[FunASR][Error] 解析响应失败: \(error)")
            onError?(error)
        }
    }
    
    private func isSentenceComplete(_ sentence: SentenceInfo) -> Bool {
        // 根据Fun-ASR的逻辑判断句子是否完整
        // 可以基于时间戳、标点符号等判断
        let text = sentence.text.trimmingCharacters(in: .whitespaces)
        
        // 检查是否以句号、问号、感叹号结尾
        let sentenceEnders: Set<Character> = ["。", "？", "！", ".", "?", "!"]
        if let lastChar = text.last, sentenceEnders.contains(lastChar) {
            return true
        }
        
        // 检查时间戳差异是否表示句子结束
        let duration = sentence.endTime - sentence.beginTime
        if duration > Int(maxSilenceDuration * 1000) { // 转换为毫秒
            return true
        }
        
        return false
    }
    
    private func handleSilenceTimeout() async {
        if !partialText.isEmpty {
            print("[FunASR] 静音超时，输出最终结果: \(partialText)")
            onFinalResult?(partialText)
            partialText = ""
        }
    }
}
