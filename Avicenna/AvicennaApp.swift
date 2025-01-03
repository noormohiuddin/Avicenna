//
//  AvicennaApp.swift
//  Avicenna
//
//  Created by Noor Bilal Mohiuddin on 2024-12-04.
//

import SwiftUI
import SwiftData

@main
struct AvicennaApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ProductView()
        }
        .modelContainer(sharedModelContainer)
    }
}
