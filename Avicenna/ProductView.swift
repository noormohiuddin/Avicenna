//
//  ProductView.swift
//  Avicenna
//
//  Created by Noor Bilal Mohiuddin on 2024-12-15.
//

import SwiftUI

struct ProductView: View {
    // Add ViewModel
    @StateObject private var viewModel = LanguageModelViewModel()
    @State private var userInput = ""
    @State private var modelResponse = ""
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading Language Model...")
            } else if let error = viewModel.errorMessage {
                Text("Error: \(error)")
            } else {
                // Add text input and response
                TextField("Ask something...", text: $userInput)
                    .textFieldStyle(.roundedBorder)
                
                Button("Generate Response") {
                    Task {
                        do {
                            modelResponse = try await viewModel.generateResponse(for: userInput)
                        } catch {
                            viewModel.errorMessage = error.localizedDescription
                        }
                    }
                }
                
                if !modelResponse.isEmpty {
                    Text("Response: \(modelResponse)")
                        .padding()
                }
                
            }
        }
        .padding()
    }
}

// Preview
#Preview {
    return ProductView()
}
