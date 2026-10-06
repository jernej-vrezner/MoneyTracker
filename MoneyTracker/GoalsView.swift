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
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date().formatted(.dateTime.month(.wide).year()))
                        .font(.system(.caption, design: .monospaced))
                        .textCase(.uppercase)
                        .foregroundStyle(Color("textSecondary"))
                    HStack {
                        Text("Cilji")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color("textPrimary"))
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "moon.fill")
                                .frame(width: 32, height: 32)
                                .background(Color("cardBackground"))
                                .clipShape(Circle())
                            Text("SI")
                                .font(.caption)
                                .padding(8)
                                .background(Color("cardBackground"))
                                .clipShape(Capsule())
                            Text("Uredi")
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.15))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding()

                List {
                    ForEach(goals) { goal in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top, spacing: 16) {
                                CircularProgressRing(progress: progress(for: goal), color: Color.accentColor)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goal.name)
                                        .font(.headline)
                                        .foregroundStyle(Color("textPrimary"))
                                    Text(goal.savedAmount.formatted(.currency(code: "EUR")))
                                        .font(.system(.title2, design: .monospaced).weight(.bold))
                                        .foregroundStyle(Color("textPrimary"))
                                    Text("od \(goal.targetAmount.formatted(.currency(code: "EUR"))) · ostane \(remaining(for: goal).formatted(.currency(code: "EUR")))")
                                        .font(.caption)
                                        .foregroundStyle(Color("textSecondary"))
                                }
                            }

                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("MESEČNO")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(Color("textSecondary"))
                                    Text(monthlyNeeded(for: goal).formatted(.currency(code: "EUR")))
                                        .font(.system(.body, design: .monospaced).weight(.semibold))
                                        .foregroundStyle(Color("textPrimary"))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color("appBackground"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("PREDVIDENO")
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(Color("textSecondary"))
                                    Text(goal.deadline.formatted(.dateTime.month(.abbreviated).year()))
                                        .font(.system(.body, design: .monospaced).weight(.semibold))
                                        .foregroundStyle(Color("textPrimary"))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                                .background(Color("appBackground"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            }

                            Text(insightText(for: goal))
                                .font(.caption)
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

                    Button {
                        showingAddGoal = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Nov cilj", systemImage: "plus")
                                .foregroundStyle(Color("textSecondary"))
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("cardBackground"))
                            .padding(.vertical, 4)
                    )
                    .listRowSeparator(.hidden)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color("appBackground"))
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

    private func remaining(for goal: Goal) -> Decimal {
        max(goal.targetAmount - goal.savedAmount, 0)
    }

    private func progress(for goal: Goal) -> Double {
        guard goal.targetAmount > 0 else { return 0 }
        return Double(truncating: (goal.savedAmount / goal.targetAmount) as NSNumber)
    }

    private func monthsRemaining(for goal: Goal) -> Int {
        let months = Calendar.current.dateComponents([.month], from: Date(), to: goal.deadline).month ?? 0
        return max(months, 1)
    }

    private func monthlyNeeded(for goal: Goal) -> Decimal {
        remaining(for: goal) / Decimal(monthsRemaining(for: goal))
    }

    private func insightText(for goal: Goal) -> String {
        "Pri mesečnem prispevku \(monthlyNeeded(for: goal).formatted(.currency(code: "EUR"))) boš cilj dosegel do \(goal.deadline.formatted(.dateTime.month(.wide).year()))."
    }
}
