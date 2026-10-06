//
//  ContentView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 9. 9. 2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @State private var showingAddView = false
    @State private var selectedFilterCategory: Category? = nil

    enum TransactionGroup: String, CaseIterable {
        case today = "Danes"
        case thisWeek = "Ta teden"
        case thisMonth = "Prej ta mesec"
        case older = "Starejše"
    }

    private func group(for date: Date) -> TransactionGroup {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return .today
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            return .thisWeek
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .month) {
            return .thisMonth
        } else {
            return .older
        }
    }

    var filteredTransactions: [Transaction] {
        guard let selectedFilterCategory else { return transactions }
        return transactions.filter { $0.category == selectedFilterCategory }
    }

    var groupedTransactions: [(TransactionGroup, [Transaction])] {
        let grouped = Dictionary(grouping: filteredTransactions) { group(for: $0.date) }
        return TransactionGroup.allCases.compactMap { group in
            guard let items = grouped[group], !items.isEmpty else { return nil }
            return (group, items.sorted { $0.date > $1.date })
        }
    }

    private func total(for items: [Transaction]) -> Decimal {
        items.reduce(Decimal(0)) { $0 + ($1.type == .income ? $1.amount : -$1.amount) }
    }

    var body: some View {
        NavigationViewWrapper {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(Date().formatted(.dateTime.month(.wide).year()))
                        .font(.system(.caption, design: .monospaced))
                        .textCase(.uppercase)
                        .foregroundStyle(Color("textSecondary"))
                    HStack {
                        Text("Transakcije")
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

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button {
                            selectedFilterCategory = nil
                        } label: {
                            Text("Vse")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedFilterCategory == nil ? Color.accentColor : Color("cardBackground"))
                                .foregroundStyle(selectedFilterCategory == nil ? .white : Color("textPrimary"))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        ForEach(categories) { category in
                            Button {
                                selectedFilterCategory = category
                            } label: {
                                Text(category.name)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedFilterCategory == category ? Color.accentColor : Color("cardBackground"))
                                    .foregroundStyle(selectedFilterCategory == category ? .white : Color("textPrimary"))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                List {
                    ForEach(groupedTransactions, id: \.0) { group, items in
                        Section(
                            header:
                                HStack {
                                    Text(group.rawValue.uppercased())
                                    Spacer()
                                    Text((total(for: items) >= 0 ? "+" : "") + total(for: items).formatted(.currency(code: "EUR")))
                                }
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Color("textSecondary"))
                        ) {
                            ForEach(items) { transaction in
                                HStack {
                                    CategoryIconBadge(
                                        icon: transaction.category?.icon ?? "questionmark.circle",
                                        color: transaction.category?.color.color ?? Color("textSecondary")
                                    )
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(transaction.note.isEmpty ? (transaction.category?.name ?? "Brez kategorije") : transaction.note)
                                            .foregroundStyle(Color("textPrimary"))
                                        Text("\(transaction.category?.name ?? "Brez kategorije")\(transaction.subcategory.map { " › " + $0.name } ?? "") · \(Calendar.current.component(.day, from: transaction.date)). \(Calendar.current.component(.month, from: transaction.date)).")
                                            .font(.caption)
                                            .foregroundStyle(Color("textSecondary"))
                                    }
                                    Spacer()
                                    Text((transaction.type == .income ? "+" : "-") + transaction.amount.formatted(.currency(code: "EUR")))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(transaction.type == .income ? Color("positiveColor") : Color("negativeColor"))
                                }
                                .padding(.vertical, 4)
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color("cardBackground"))
                                        .padding(.vertical, 4)
                                )
                                .listRowSeparator(.hidden)
                            }
                            .onDelete { offsets in
                                deleteItems(transactions: items, offsets: offsets)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(Color("appBackground"))
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
            }
            .sheet(isPresented: $showingAddView) {
                AddTransactionView()
            }
        }
    }

    private func deleteItems(transactions itemsToDelete: [Transaction], offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(itemsToDelete[index])
            }
        }
    }
}

fileprivate struct NavigationViewWrapper<Content: View>: View {
    let content: () -> Content

    var body: some View {
#if os(macOS)
        NavigationSplitView {
            content()
        } detail: {
            Text("Select an item")
        }
#else
        NavigationStack {
            content()
        }
#endif
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
