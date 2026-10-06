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
            Subscription.self,
            Subcategory.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var showingAddTransaction = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
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
                    SubscriptionsView()
                        .tabItem {
                            Label("Naročnine", systemImage: "creditcard")
                        }
                    CalendarView()
                        .tabItem {
                            Label("Kalendar", systemImage: "calendar")
                        }
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingAddTransaction = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                                .shadow(radius: 6, y: 3)
                        }
                        .padding(.trailing, 20)
                    }
                    .padding(.bottom, 70)
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddTransactionView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
