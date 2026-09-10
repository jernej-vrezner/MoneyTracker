//
//  CategoriesView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [Category]
    @State private var showingAddCategory = false
    @Query private var transactions: [Transaction]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    VStack(alignment: .leading){
                        HStack {
                            Circle()
                                .fill(category.color.color)
                                .frame(width: 12, height: 12)
                            Text(category.name)
                            Spacer()
                            Text(category.monthlyLimit.formatted(.currency(code: "EUR")))
                        }
                        ProgressView(
                            value: Double(truncating: spent(for: category) as NSNumber),
                            total: Double(truncating: category.monthlyLimit as NSNumber)
                        )
                        .tint(spent(for: category) > category.monthlyLimit ? .red : .blue)
                    }
                }
                .onDelete(perform: deleteCategories)
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddCategory = true
                    } label: {
                        Label("Add Category", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
        }
    }

    private func deleteCategories(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(categories[index])
            }
        }
    }
    
    private func spent(for category: Category) -> Decimal {
        transactions
            .filter { $0.category == category && $0.type == .expense && Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
}

