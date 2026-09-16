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
    
    var body: some View {
        NavigationViewWrapper {
            List {
                ForEach(transactions) { transaction in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
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
                .onDelete(perform: deleteItems)
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

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(transactions[index])
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
        NavigationStack{
            content()
        }
        
#endif
        
    }
    
}

#Preview {
    ContentView()
        .modelContainer(for: Transaction.self, inMemory: true)
}
