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
            Investment.self,
            InvestmentTrade.self,
            Account.self,
            AccountTransfer.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var showingAddTransaction = false
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("subscriptionReminders") private var subscriptionReminders = false
    @Environment(\.scenePhase) private var scenePhase

    private var preferredScheme: ColorScheme? {
        switch appearance {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
    
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
                    StatisticsView()
                        .tabItem {
                            Label("Statistika", systemImage: "chart.pie")
                        }
                    CategoriesView()
                        .tabItem {
                            Label("Kategorije", systemImage: "folder")
                        }
                    SavingsView()
                        .tabItem {
                            Label("Varčevanje", systemImage: "chart.line.uptrend.xyaxis")
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
            .preferredColorScheme(preferredScheme)
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    WidgetSync.update(context: sharedModelContainer.mainContext)
                    let subscriptions = (try? sharedModelContainer.mainContext.fetch(FetchDescriptor<Subscription>())) ?? []
                    Task {
                        await Reminders.applySubscriptionReminders(enabled: subscriptionReminders, subscriptions: subscriptions)
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
