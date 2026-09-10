//
//  AddContributionView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//
import SwiftUI
import SwiftData

struct AddContributionView: View {
    let goal: Goal
    @State var amount: Decimal = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text("Znesek prispevka")) {
                TextField("Znesek", value: $amount, format: .currency(code: "EUR"))
            }
            Section {
                Button("Dodaj") {
                    goal.savedAmount += amount
                    dismiss()
                }
            }
        }
    }
}
