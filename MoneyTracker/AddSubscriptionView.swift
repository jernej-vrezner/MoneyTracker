//
//  AddSubscriptionView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 11. 9. 2026.
//

import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @State var name: String = ""
    @State var amount: Decimal = 0
    @State var billingDay: Int = 1
    @State var selectedCategory: Category? = nil
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]

    var body: some View {
        Form {
            Section(header: Text("Ime")) {
                TextField("Ime", text: $name)
            }
            Section(header: Text("Znesek")) {
                TextField("Znesek", value: $amount, format: .currency(code: "EUR"))
            }
            Section(header: Text("Dan obračuna")) {
                TextField("Dan v mesecu (1-31)", value: $billingDay, format: .number)
            }
            Section(header: Text("Kategorija")) {
                Picker("Kategorija", selection: $selectedCategory) {
                    Text("Brez kategorije").tag(nil as Category?)
                    ForEach(categories) { category in
                        Text(category.name).tag(category as Category?)
                    }
                }
            }
            Section {
                Button("Shrani") {
                    let newSubscription = Subscription(name: name, amount: amount, billingDay: billingDay, category: selectedCategory)
                    modelContext.insert(newSubscription)
                    dismiss()
                }
            }
        }
    }
}
