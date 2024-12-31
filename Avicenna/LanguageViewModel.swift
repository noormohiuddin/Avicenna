//
//  LanguageViewModel.swift
//  Avicenna
//
//  Created by Noor Bilal Mohiuddin on 2024-12-14.
//
import SwiftUI
import CoreML
import Tokenizers

class LanguageModelViewModel: ObservableObject {
    @Published var model: MLModel?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    init() {
        Task {
            await loadModel()
//            DispatchQueue.main.async {
//                self.isLoading = false
//            }
        }
    }
    
//    private func loadModel() async {
//        do {
//            let config = MLModelConfiguration()
//            //let modelURL = Bundle.main.url(forResource: "OpenELM-270M-Instruct-128-float32", withExtension: "mlpackage")!
//            
//            // Load the model
////            guard let modelURL = Bundle.main.url(forResource: "OpenELM-270M-Instruct-128-float32"),
////                  let model = try? MLModel(contentsOf: modelURL) else {
////                fatalError("Failed to load model")
////            }
//            
//            self.model = try MLModel(contentsOf: modelURL, configuration: config)
//            
//            DispatchQueue.main.async {
//                self.isLoading = false
//            }
//        } catch {
//            DispatchQueue.main.async {
//                self.errorMessage = error.localizedDescription
//                self.isLoading = false
//            }
//        }
//    }
    
    private func loadModel() async {
        do {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndGPU
            config.allowLowPrecisionAccumulationOnGPU = true
            config.preferredMetalDevice = MTLCreateSystemDefaultDevice()
            
            // Optional: Add loading progress
//            let progress = Progress(totalUnitCount: 100)
//            progress.becomeCurrent(withPendingUnitCount: 100)
            
            guard let modelURL = Bundle.main.url(forResource: "openELM270M",
                                                       withExtension: "mlmodelc") else {
                        throw NSError(domain: "ModelError",
                                     code: -1,
                                     userInfo: [NSLocalizedDescriptionKey: "Model file not found"])
                    }
                        
            self.model = try MLModel(contentsOf: modelURL,
                                         configuration: config)
                                    
            DispatchQueue.main.async {
                self.isLoading = false
            }
        } catch {
            // Handle errors
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            print("Error loading model: \(error.localizedDescription)")
        }
    }
    
//    func generateResponse(for input: String) async throws -> String {
//            guard let model = self.model else {
//                throw NSError(domain: "ModelError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
//            }
//            
//            // Initialize tokenizer
//            let tokenizer = try await AutoTokenizer.from(pretrained: "pcuenq/Llama-2-7b-chat-coreml")
//
//            // Tokenize input
//            let tokens = tokenizer(input)
//            
//            // Create input array with shape [1, 128]
//            let shape: [NSNumber] = [1, 128]
//            guard let inputArray = try? MLMultiArray(shape: shape, dataType: .int32) else {
//                throw NSError(domain: "InputError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create input array"])
//            }
//            
//            // Fill the input array with tokens, padding with 0s if needed
//            for i in 0..<min(tokens.count, 128) {
//                inputArray[i] = NSNumber(value: tokens[i])
//            }
//            // Pad remaining positions with 0s if input is shorter than 128
//            for i in tokens.count..<128 {
//                inputArray[i] = 0
//            }
//            
//            // Create feature dictionary and get prediction
//            let inputFeatures = try MLDictionaryFeatureProvider(dictionary: ["input_ids": inputArray])
//            let prediction = try await model.prediction(from: inputFeatures)
//            
//            // Get logits from output
//            guard let logits = prediction.featureValue(for: "logits")?.multiArrayValue else {
//                throw NSError(domain: "OutputError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get logits"])
//            }
//            
//            // Process logits to get token predictions
//            // For each position, get the token with highest probability
//            var outputTokens: [Int] = []
//            for pos in 0..<128 {
//                var maxVal: Float = -Float.infinity
//                var maxIndex = 0
//                
//                // For each position, find the token with highest probability
//                for vocabIndex in 0..<32000 {
//                    let flatIndex = pos * 32000 + vocabIndex
//                    let value = logits[flatIndex].floatValue
//                    if value > maxVal {
//                        maxVal = value
//                        maxIndex = vocabIndex
//                    }
//                }
//                outputTokens.append(maxIndex)
//            }
//            
//            // Decode tokens back to text
//            return tokenizer.decode(tokens: outputTokens)
//        }
    
    func generateResponse(for input: String) async throws -> String {
            guard let model = self.model else {
                throw NSError(domain: "ModelError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Model not loaded"])
            }
            
            // Initialize tokenizer
            let tokenizer = try await AutoTokenizer.from(pretrained: "pcuenq/Llama-2-7b-chat-coreml")
            
            // Tokenize input
            let tokens = tokenizer(input)
            
            // Create input array with shape [1, 128]
            let shape: [NSNumber] = [1, 128]
            guard let inputArray = try? MLMultiArray(shape: shape, dataType: .int32) else {
                throw NSError(domain: "InputError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create input array"])
            }
            
            // Fill the input array with tokens, padding with 0s if needed
            for i in 0..<min(tokens.count, 128) {
                inputArray[i] = NSNumber(value: tokens[i])
            }
            for i in tokens.count..<128 {
                inputArray[i] = 0
            }
            
            // Configure generation parameters
            let generationConfig = GenerationConfig(
                maxLength: 128,
                maxNewTokens: 128 - tokens.count, // Only generate up to remaining space
                temperature: 0.7,  // Controls randomness (0.0-1.0, higher = more random)
                topK: 50,         // Limits to top K most likely tokens
                topP: 0.95,       // Nucleus sampling threshold
                repetitionPenalty: 1.1, // Penalize repeated tokens
                doSample: true    // Use sampling instead of greedy decoding
            )
            
            var generatedTokens: [Int] = []
            var currentLength = tokens.count
            
            while currentLength < 128 {
                // Get model prediction
                let inputFeatures = try MLDictionaryFeatureProvider(dictionary: ["input_ids": inputArray])
                let prediction = try await model.prediction(from: inputFeatures)
                
                guard let logits = prediction.featureValue(for: "logits")?.multiArrayValue else {
                    throw NSError(domain: "OutputError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get logits"])
                }
                
                // Get logits for the next token prediction (last position)
                var nextTokenLogits = [Float]()
                let vocabSize = 32000
                let position = currentLength - 1
                
                for vocabIndex in 0..<vocabSize {
                    let flatIndex = position * vocabSize + vocabIndex
                    nextTokenLogits.append(logits[flatIndex].floatValue)
                }
                
                // Apply temperature
                if generationConfig.temperature != 1.0 {
                    nextTokenLogits = nextTokenLogits.map { $0 / generationConfig.temperature }
                }
                
                // Apply top-k filtering
                var topKLogits = nextTokenLogits
                if generationConfig.topK > 0 {
                    let sortedIndices = topKLogits.indices.sorted { topKLogits[$0] > topKLogits[$1] }
                    let threshold = topKLogits[sortedIndices[generationConfig.topK - 1]]
                    for i in 0..<topKLogits.count {
                        if topKLogits[i] < threshold {
                            topKLogits[i] = -Float.infinity
                        }
                    }
                }
                
                // Convert to probabilities using softmax
                let maxLogit = topKLogits.max() ?? 0
                let expLogits = topKLogits.map { exp($0 - maxLogit) }
                let sum = expLogits.reduce(0, +)
                let probs = expLogits.map { $0 / sum }
                
                // Sample from the probability distribution
                let random = Float.random(in: 0...1)
                var cumSum: Float = 0
                var nextToken = 0
                
                for (index, prob) in probs.enumerated() {
                    cumSum += prob
                    if random <= cumSum {
                        nextToken = index
                        break
                    }
                }
                
                // Add the new token
                generatedTokens.append(nextToken)
                inputArray[currentLength] = NSNumber(value: nextToken)
                currentLength += 1
                
                // Check for end of sequence token or max length
                if nextToken == tokenizer.eosTokenId || currentLength >= generationConfig.maxLength {
                    break
                }
            }
            
            // Decode generated tokens
            return tokenizer.decode(tokens: generatedTokens)
        }

    // Generation configuration struct
    struct GenerationConfig {
        let maxLength: Int
        let maxNewTokens: Int
        let temperature: Float
        let topK: Int
        let topP: Float
        let repetitionPenalty: Float
        let doSample: Bool
    }
}
