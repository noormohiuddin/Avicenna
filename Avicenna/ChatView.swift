//
//  NewChat.swift
//  Avicenna
//
//  Created by Noor Bilal Mohiuddin on 2024-12-14.
//

import SwiftUI
import CoreML
import Generation
import Models

struct ChatView: View {
    @State private var languageModel: LanguageModel? = nil
    
    init() {
        self.languageModel = loadModel()
    }

    var body: some View {
        VStack {
            Text("Hello, World!")
        }
    }
    
    
    private func loadModel() -> LanguageModel {
        let languageModel = try! LanguageModel(model: MLModel(contentsOf: URL(fileURLWithPath: "BERTSQUADFP16.mlmodel")))
        
        return languageModel
    }
}
