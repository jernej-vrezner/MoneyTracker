//
//  BudgetEditView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 17. 9. 2026.
//

import SwiftUI
import SwiftData

struct BudgetEditView: View {
    @Query private var categories: [Category]
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCategory = false

    var totalBudget: Decimal {
        categories.reduce(0) { $0 + $1.monthlyLimit }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Text("Skupni mesečni limit")
                        Spacer()
                        Text(totalBudget.formatted(.currency(code: "EUR")))
                            .font(.system(.body, design: .monospaced).weight(.semibold))
                    }
                }
                Section {
                    ForEach(categories) { category in
                        HStack {
                            CategoryIconBadge(icon: category.icon, color: category.color.color)
                            Text(category.name)
                            Spacer()
                            Button {
                                category.monthlyLimit = max(10, category.monthlyLimit - 10)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                            }
                            .buttonStyle(.plain)
                            Text(category.monthlyLimit.formatted(.currency(code: "EUR")))
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 70)
                            Button {
                                category.monthlyLimit += 10
                            } label: {
                                Image(systemName: "plus.circle.fill")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Button {
                        showingAddCategory = true
                    } label: {
                        Label("Nova kategorija", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Uredi budget in kategorije")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Končaj") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
        }
    }
}
