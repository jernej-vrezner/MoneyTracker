//
//  SubscriptionsView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 11. 9. 2026.
//


import SwiftUI
import SwiftData


struct SubscriptionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var subscriptions: [Subscription]
    @State private var showingAddSubscription = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(subscriptions) { subscription in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(subscription.name)
                            Text("Dan obračuna: \(subscription.billingDay)")
                                .font(.caption)
                        }
                        Spacer()
                        Text(subscription.amount.formatted(.currency(code: "EUR")))
                    }
                }
                .onDelete(perform: deleteSubscriptions)
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        showingAddSubscription = true
                    } label: {
                        Label("Add Subscription", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSubscription) {
                AddSubscriptionView()
            }
        }
    }

    private func deleteSubscriptions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(subscriptions[index])
            }
        }
    }
}
