//
//  GoalsView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//
import SwiftUI
import SwiftData


struct GoalsView: View {
    @Query private var goals: [Goal]
    @State private var showingAddGoal = false
    @State private var goalForContribution: Goal? = nil
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(goals) { goal in
                    VStack(alignment: .leading) {
                        Text(goal.name)
                        ProgressView(
                            value: min(Double(truncating: goal.savedAmount as NSNumber), Double(truncating: goal.targetAmount as NSNumber)),
                            total: Double(truncating: goal.targetAmount as NSNumber)
                        )
                        Text("\(goal.savedAmount.formatted(.currency(code: "EUR"))) od \(goal.targetAmount.formatted(.currency(code: "EUR")))")
                        Button("Dodaj prispevek") {
                            goalForContribution = goal
                        }
                    }
                }
                .onDelete(perform: deleteGoals)
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddGoal = true
                    } label: {
                        Label("Add Goal", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGoal) {
                AddGoalView()
            }
            .sheet(item: $goalForContribution) { goal in
                AddContributionView(goal: goal)
            }
        }
    }
    private func deleteGoals(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(goals[index])
            }
        }
    }
    
  
}
