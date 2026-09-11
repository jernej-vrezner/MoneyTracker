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
                    VStack(alignment: .leading) {
                        HStack {
                            Text(transaction.category?.name ?? "Brez kategorije")
                            Spacer()
                            Text(transaction.amount.formatted(.currency(code: "EUR")))
                        }
                        Text("\(transaction.type.rawValue) • \(transaction.date.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                        if !transaction.note.isEmpty {
                            Text(transaction.note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
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
