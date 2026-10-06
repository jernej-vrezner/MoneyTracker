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
    @State private var categoryToEdit: Category? = nil
    @State private var expandedCategories: Set<PersistentIdentifier> = []
    @Query private var transactions: [Transaction]
    @Query private var subscriptions: [Subscription]

    private var subscriptionsMonthlyTotal: Decimal {
        subscriptions.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(categories) { category in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            CategoryIconBadge(icon: category.icon, color: category.color.color)
                            Text(category.name)
                                .foregroundStyle(Color("textPrimary"))
                            Spacer()
                            Text(category.monthlyLimit.formatted(.currency(code: "EUR")))
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(Color("textSecondary"))
                            Image(systemName: expandedCategories.contains(category.persistentModelID) ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(Color("textSecondary"))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation {
                                if expandedCategories.contains(category.persistentModelID) {
                                    expandedCategories.remove(category.persistentModelID)
                                } else {
                                    expandedCategories.insert(category.persistentModelID)
                                }
                            }
                        }

                        CategoryProgressBar(
                            progress: Double(truncating: spent(for: category) as NSNumber) / Double(truncating: category.monthlyLimit as NSNumber),
                            color: spent(for: category) > category.monthlyLimit ? Color("negativeColor") : category.color.color
                        )

                        if expandedCategories.contains(category.persistentModelID) {
                            let subs = (category.subcategories ?? []).sorted { $0.name < $1.name }
                            if subs.isEmpty {
                                Text("Ni podkategorij")
                                    .font(.caption)
                                    .foregroundStyle(Color("textSecondary"))
                            } else {
                                ForEach(subs) { sub in
                                    VStack(alignment: .leading, spacing: 4) {
                                        HStack {
                                            Text(sub.name)
                                                .font(.subheadline)
                                                .foregroundStyle(Color("textPrimary"))
                                            Spacer()
                                            Text(spent(for: sub).formatted(.currency(code: "EUR")) + (sub.monthlyLimit.map { " / " + $0.formatted(.currency(code: "EUR")) } ?? ""))
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundStyle(Color("textSecondary"))
                                        }
                                        if let limit = sub.monthlyLimit, limit > 0 {
                                            CategoryProgressBar(
                                                progress: Double(truncating: spent(for: sub) as NSNumber) / Double(truncating: limit as NSNumber),
                                                color: spent(for: sub) > limit ? Color("negativeColor") : category.color.color
                                            )
                                        }
                                    }
                                    .padding(.leading, 12)
                                }
                            }

                            Button {
                                categoryToEdit = category
                            } label: {
                                Label("Uredi", systemImage: "pencil")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color("appBackground"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Color("textPrimary"))
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color("cardBackground"))
                            .padding(.vertical, 4)
                    )
                    .listRowSeparator(.hidden)
                }
                .onDelete(perform: deleteCategories)

                Button {
                    showingAddCategory = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Nova kategorija", systemImage: "plus")
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

                NavigationLink {
                    SubscriptionsView()
                } label: {
                    HStack {
                        Image(systemName: "creditcard")
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 32, height: 32)
                            .background(Color.accentColor.opacity(0.15))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Naročnine")
                                .foregroundStyle(Color("textPrimary"))
                            Text("\(subscriptions.count) · \(subscriptionsMonthlyTotal.formatted(.currency(code: "EUR"))) / mesec")
                                .font(.caption)
                                .foregroundStyle(Color("textSecondary"))
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("cardBackground"))
                        .padding(.vertical, 4)
                )
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
           
            .sheet(isPresented: $showingAddCategory) {
                AddCategoryView()
            }
            .sheet(item: $categoryToEdit) { category in
                EditCategoryView(category: category)
            }
#if DEBUG
            .toolbar {
                ToolbarItem {
                    Menu {
                        Button("Dodaj testne podatke") {
                            TestData.seed(in: modelContext, categories: categories)
                        }
                        Button("Izbriši VSE transakcije", role: .destructive) {
                            try? modelContext.delete(model: Transaction.self)
                        }
                    } label: {
                        Image(systemName: "wrench.and.screwdriver")
                    }
                }
            }
#endif
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
    
    private func spent(for subcategory: Subcategory) -> Decimal {
        transactions
            .filter { $0.subcategory == subcategory && $0.type == .expense && Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
}

