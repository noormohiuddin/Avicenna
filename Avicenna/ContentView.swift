//
//  ContentView.swift
//  Avicenna
//
//  Created by Noor Bilal Mohiuddin on 2024-12-04.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        ChatView()
    }

    
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
