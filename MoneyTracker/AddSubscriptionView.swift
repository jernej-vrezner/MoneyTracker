//
//  AddSubscriptionView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 11. 9. 2026.
//

import SwiftUI
import SwiftData

struct AddSubscriptionView: View {
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var billingDay: Int = 1
    @State private var selectedCategory: Category? = nil
    @State private var selectedSubcategory: Subcategory? = nil
    @State private var note: String = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]

    let subscriptionToEdit: Subscription?

    init(subscription: Subscription? = nil) {
        self.subscriptionToEdit = subscription
        if let subscription {
            _name = State(initialValue: subscription.name)
            _amountText = State(initialValue: "\(subscription.amount)".replacingOccurrences(of: ".", with: ","))
            _billingDay = State(initialValue: subscription.billingDay)
            _selectedCategory = State(initialValue: subscription.category)
            _selectedSubcategory = State(initialValue: subscription.subcategory)
            _note = State(initialValue: subscription.note)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("IME").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    TextField("Ime naročnine", text: $name)
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: Text("ZNESEK NA MESEC").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    TextField("0,00 €", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                .listRowBackground(Color("cardBackground"))

                Section(
                    header: Text("DAN OBRAČUNA").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary")),
                    footer: Text("Naročnina se obračuna vsak mesec na ta dan. V krajših mesecih se obračuna zadnji dan v mesecu.")
                ) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(1...31, id: \.self) { day in
                            Button {
                                billingDay = day
                            } label: {
                                Text("\(day)")
                                    .font(.system(.subheadline, design: .monospaced))
                                    .frame(width: 34, height: 34)
                                    .background(billingDay == day ? Color.accentColor : Color.clear)
                                    .foregroundStyle(billingDay == day ? .white : Color("textPrimary"))
                                    .clipShape(Circle())
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: Text("KATEGORIJA").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    CategoryPillPicker(
                        categories: categories,
                        selectedCategory: $selectedCategory,
                        selectedSubcategory: $selectedSubcategory
                    )
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color("cardBackground"))
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))

                Section(header: Text("OPOMBA").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    TextField("Opomba (neobvezno)", text: $note)
                }
                .listRowBackground(Color("cardBackground"))
            }
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
            .navigationTitle(subscriptionToEdit == nil ? "Nova naročnina" : "Uredi naročnino")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Prekliči") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Shrani") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let amount = Decimal(string: amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let subscription = subscriptionToEdit {
            subscription.name = trimmedName
            subscription.amount = amount
            subscription.billingDay = billingDay
            subscription.category = selectedCategory
            subscription.subcategory = selectedSubcategory
            subscription.note = note
        } else {
            let newSubscription = Subscription(name: trimmedName, amount: amount, billingDay: billingDay, category: selectedCategory)
            modelContext.insert(newSubscription)
            newSubscription.subcategory = selectedSubcategory
            newSubscription.note = note
        }
        dismiss()
    }
}
