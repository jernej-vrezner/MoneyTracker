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
    @State private var amountInput: String = "0"
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                VStack(spacing: 4) {
                    Text(amountInput.replacingOccurrences(of: ".", with: ",") + " €")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color("textPrimary"))
                    Text("Znesek prispevka")
                        .font(.subheadline)
                        .foregroundStyle(Color("textSecondary"))
                }
                .padding(.top, 24)

                Spacer()

                NumericKeypad(input: $amountInput)

                Spacer()
            }
            .navigationTitle("Dodaj prispevek")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Prekliči") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Dodaj") {
                        goal.savedAmount += Decimal(string: amountInput) ?? 0
                        dismiss()
                    }
                }
            }
        }
    }
}
