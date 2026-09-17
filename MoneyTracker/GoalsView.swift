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
                    VStack(alignment: .leading, spacing: 6) {
                        Text(goal.name)
                            .foregroundStyle(Color("textPrimary"))
                        CategoryProgressBar(
                            progress: Double(truncating: goal.savedAmount as NSNumber) / Double(truncating: goal.targetAmount as NSNumber),
                            color: Color.accentColor
                        )
                        .tint(Color.accentColor)
                        Text("\(goal.savedAmount.formatted(.currency(code: "EUR"))) od \(goal.targetAmount.formatted(.currency(code: "EUR")))")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color("textSecondary"))
                        Button("Dodaj prispevek") {
                            goalForContribution = goal
                        }
                        .pillStyle()
                        .foregroundStyle(Color.accentColor)
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("cardBackground"))
                            .padding(.vertical, 4)
                    )
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteGoals)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
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
