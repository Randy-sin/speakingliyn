//
//  WelcomeView.swift
//  speaking
//
//  Created by Randy on 24/9/2025.
//

import SwiftUI
import Combine
import Charts

struct WelcomeView: View {
    @State private var animateTitle = false
    @State private var animateSubtitle = false
    @State private var animateButton = false
    @State private var showPersonalityTest = false
    @State private var floatingIconOffset: CGFloat = 0
    @State private var showLanguageSelection = true
    @State private var selectedLanguage: String? = nil
    @State private var selectedPurpose: String? = nil

    var body: some View {
        ZStack {
            // Liquid gradient background
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue, Color.green]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 300, height: 300)
                        .blur(radius: 50)
                        .offset(x: -100, y: -200)
                        .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: floatingIconOffset)
                )

            if showLanguageSelection {
                LanguageSelectionView(onSelectionComplete: { language, purpose in
                    selectedLanguage = language
                    selectedPurpose = purpose
                    showLanguageSelection = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showPersonalityTest = true
                    }
                })
            } else {
                VStack(spacing: 40) {
                    Spacer()

                    // Dynamic icon
                    Image(systemName: "person.circle")
                        .font(.system(size: 80, weight: .ultraLight))
                        .foregroundColor(.white)
                        .scaleEffect(animateTitle ? 1.0 : 0.8)
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 1.0).delay(0.2), value: animateTitle)
                        .offset(y: floatingIconOffset)
                        .onAppear {
                            withAnimation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                                floatingIconOffset = -10
                            }
                        }

                    // Title
                    Text("Welcome to Speaking")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(animateTitle ? 1.0 : 0.9)
                        .opacity(animateTitle ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.8).delay(0.5), value: animateTitle)

                    // Subtitle
                    Text("Discover your personalized AI tutor and enhance your speaking skills.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .opacity(animateSubtitle ? 1.0 : 0.0)
                        .offset(y: animateSubtitle ? 0 : 20)
                        .animation(.easeOut(duration: 0.8).delay(0.8), value: animateSubtitle)

                    Spacer()

                    // Start button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showPersonalityTest = true
                        }
                    }) {
                        HStack(spacing: 10) {
                            Text("Start Personality Test")
                                .font(.system(size: 20, weight: .semibold))

                            Image(systemName: "arrow.right")
                                .font(.system(size: 16, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(15)
                        .shadow(color: Color.blue.opacity(0.5), radius: 10, x: 0, y: 5)
                    }
                    .scaleEffect(animateButton ? 1.0 : 0.9)
                    .opacity(animateButton ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.6).delay(1.1), value: animateButton)

                    Spacer()
                }
                .padding(.horizontal, 20)
            }
        }
        .fullScreenCover(isPresented: $showPersonalityTest) {
            PersonalityTestView()
        }
        .onAppear {
            animateTitle = true
            animateSubtitle = true
            animateButton = true
        }
    }
}

struct LanguageSelectionView: View {
    let onSelectionComplete: (String, String) -> Void

    @State private var selectedLanguage: String = "English"
    @State private var selectedPurpose: String = "Daily Use"

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Your Preferences")
                .font(.title)
                .foregroundColor(.white)

            Picker("Language", selection: $selectedLanguage) {
                Text("English").tag("English")
                Text("Spanish").tag("Spanish")
                Text("French").tag("French")
            }
            .pickerStyle(SegmentedPickerStyle())

            Picker("Purpose", selection: $selectedPurpose) {
                Text("Daily Use").tag("Daily Use")
                Text("Business").tag("Business")
                Text("Other").tag("Other")
            }
            .pickerStyle(SegmentedPickerStyle())

            Button(action: {
                onSelectionComplete(selectedLanguage, selectedPurpose)
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(15)
        .shadow(radius: 10)
    }
}

struct PersonalityTestView: View {
    @State private var currentQuestionIndex = 0
    @State private var selectedAnswer: String? = nil
    @State private var showResults = false
    @State private var answers: [String] = []
    @State private var questions: [Question] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("加载中...")
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if showResults {
                ResultsView(answers: answers)
            } else {
                QuestionView(
                    question: questions[currentQuestionIndex],
                    selectedAnswer: $selectedAnswer,
                    onNext: handleNext
                )
            }
        }
        .padding()
        .navigationTitle("性格测试")
        .onAppear(perform: fetchQuestions)
    }

    private func fetchQuestions() {
        guard let url = URL(string: "https://api.example.com/questions") else {
            errorMessage = "无效的URL"
            isLoading = false
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "加载失败: \(error.localizedDescription)"
                } else if let data = data {
                    do {
                        let decodedQuestions = try JSONDecoder().decode([Question].self, from: data)
                        questions = decodedQuestions
                    } catch {
                        errorMessage = "解析数据失败"
                    }
                }
                isLoading = false
            }
        }.resume()
    }

    private func handleNext() {
        if let answer = selectedAnswer {
            answers.append(answer)
            if currentQuestionIndex < questions.count - 1 {
                currentQuestionIndex += 1
                selectedAnswer = nil
            } else {
                submitResults()
            }
        }
    }

    private func submitResults() {
        guard let url = URL(string: "https://api.example.com/submit") else {
            errorMessage = "无效的URL"
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let body = ["answers": answers]
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            errorMessage = "编码数据失败"
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    errorMessage = "提交失败: \(error.localizedDescription)"
                } else {
                    showResults = true
                }
            }
        }.resume()
    }
}

struct QuestionView: View {
    let question: Question
    @Binding var selectedAnswer: String?
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 问题标题
            Text(question.text)
                .font(.headline)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.blue.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )

            // 动态装饰元素
            HStack {
                Circle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .offset(x: -20, y: -20)
                    .animation(Animation.easeInOut(duration: 2).repeatForever(autoreverses: true), value: UUID())

                Spacer()

                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .offset(x: 20, y: 20)
                    .animation(Animation.easeInOut(duration: 3).repeatForever(autoreverses: true), value: UUID())
            }

            // 答案选项
            ForEach(question.options, id: \ .self) { option in
                Button(action: {
                    selectedAnswer = option
                }) {
                    HStack {
                        Text(option)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedAnswer == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 10).stroke(selectedAnswer == option ? Color.blue : Color.gray))
                }
            }

            // 下一步按钮
            Button("下一步", action: onNext)
                .disabled(selectedAnswer == nil)
                .padding()
                .background(selectedAnswer == nil ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
}

struct ResultsView: View {
    let answers: [String]

    var body: some View {
        VStack {
            Text("测试结果")
                .font(.largeTitle)
                .padding()

            let matchedTutor = matchTutor(for: answers)

            VStack(spacing: 20) {
                Text("为你匹配的AI导师")
                    .font(.title2)
                    .padding(.top)

                Text(matchedTutor.name)
                    .font(.headline)

                Text(matchedTutor.description)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)

                Button("开始学习") {
                    // 对接功能，例如导航到学习界面
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
    }
}

struct Tutor {
    let name: String
    let description: String
}

struct Question: Codable, Identifiable {
    let id: UUID
    let text: String
    let options: [String]
    
    init(text: String, options: [String]) {
        self.id = UUID()
        self.text = text
        self.options = options
    }
}

struct TutorPromptGenerator {
    static func generatePrompt(for tutor: Tutor, basedOn answers: [String]) -> String {
        let basePrompt = "你是一个AI导师，名字是\(tutor.name)。你的任务是帮助学生根据他们的学习风格提高学习效率。"

        let learningStyle: String
        if answers.contains("A") {
            learningStyle = "学生喜欢详细的步骤指导，一步一步学习。"
        } else if answers.contains("B") {
            learningStyle = "学生喜欢先了解整体概念，再深入细节。"
        } else if answers.contains("C") {
            learningStyle = "学生喜欢通过实践尝试，从错误中学习。"
        } else {
            learningStyle = "学生喜欢与他人讨论，从不同角度理解。"
        }

        return "\(basePrompt) \(learningStyle) 请根据这些信息制定一个学习计划。"
    }
}

#Preview {
    WelcomeView()
}

// MARK: - Helper Functions
func matchTutor(for answers: [String]) -> Tutor {
    // 简化的导师匹配逻辑
    if answers.contains(where: { $0.contains("A") || $0.contains("详细") }) {
        return Tutor(name: "分析师 Bowen", description: "喜欢详细分析和逻辑思考的AI导师，适合喜欢步骤化学习的用户。")
    } else if answers.contains(where: { $0.contains("B") || $0.contains("实践") }) {
        return Tutor(name: "协作者 Mia", description: "喜欢互动和实践的AI导师，适合喜欢通过对话练习的用户。")
    } else {
        return Tutor(name: "探索者 Ella", description: "好奇心强、善于启发的AI导师，适合喜欢探索和发现的用户。")
    }
}

#Preview {
    PersonalityTestView()
}

