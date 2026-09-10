//
//  MoneyTrackerApp.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 9. 9. 2026.
//

import SwiftUI
import SwiftData


@main
struct MoneyTrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Goal.self,
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
            TabView {
                DashboardView()
                    .tabItem {
                        Label("Pregled", systemImage: "chart.bar")
                    }
                        ContentView()
                    .tabItem {
                        Label("Transakcije", systemImage: "list.bullet")
                    }
                CategoriesView()
                    .tabItem {
                        Label("Kategorije", systemImage: "folder")
                    }
                GoalsView()
                    .tabItem {
                        Label("Cilji", systemImage: "target")
                    }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
