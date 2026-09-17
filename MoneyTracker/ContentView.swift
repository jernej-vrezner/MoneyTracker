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
    @State private var showingAddView = false

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

    var groupedTransactions: [(TransactionGroup, [Transaction])] {
        let grouped = Dictionary(grouping: transactions) { group(for: $0.date) }
        return TransactionGroup.allCases.compactMap { group in
            guard let items = grouped[group], !items.isEmpty else { return nil }
            return (group, items.sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        NavigationViewWrapper {
            List {
                ForEach(groupedTransactions, id: \.0) { group, items in
                    Section(header: Text(group.rawValue).foregroundStyle(Color("textSecondary"))) {
                        ForEach(items) { transaction in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    CategoryIconBadge(
                                        icon: transaction.category?.icon ?? "questionmark.circle",
                                        color: transaction.category?.color.color ?? Color("textSecondary")
                                    )
                                    Text(transaction.category?.name ?? "Brez kategorije")
                                        .foregroundStyle(Color("textPrimary"))
                                    Spacer()
                                    Text(transaction.amount.formatted(.currency(code: "EUR")))
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundStyle(transaction.type == .income ? Color("positiveColor") : Color("negativeColor"))
                                }
                                Text("\(transaction.type.rawValue) • \(transaction.date.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption)
                                    .foregroundStyle(Color("textSecondary"))
                                if !transaction.note.isEmpty {
                                    Text(transaction.note)
                                        .font(.caption)
                                        .foregroundStyle(Color("textSecondary"))
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
                        .onDelete { offsets in
                            deleteItems(transactions: items, offsets: offsets)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
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
                ToolbarItem {
                    Button {
                        showingAddView = true
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
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
