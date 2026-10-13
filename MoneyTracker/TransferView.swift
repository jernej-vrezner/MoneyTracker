//
//  TransferView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 13. 10. 2026.
//

import SwiftUI
import SwiftData

struct TransferView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.createdAt) private var accounts: [Account]

    @State private var amountInput = "0"
    @State private var fromAccount: Account? = nil
    @State private var toAccount: Account? = nil
    @State private var date = Date()
    @State private var note = ""
    @State private var showingDatePicker = false

    private var amount: Decimal {
        Decimal(string: amountInput) ?? 0
    }

    private var canSave: Bool {
        guard let fromAccount, let toAccount else { return false }
        return fromAccount != toAccount && amount > 0
    }

    private func euro(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR"))
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Color("textSecondary"))
            .padding(.horizontal)
    }

    var body: some View {
        NavigationStack {
            if accounts.count < 2 {
                Text("Za prenos potrebuješ vsaj dva računa.")
                    .foregroundStyle(Color("textSecondary"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("appBackground"))
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Zapri") { dismiss() }
                        }
                    }
            } else {
                content
            }
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 4) {
                Text(amountInput.replacingOccurrences(of: ".", with: ",") + " €")
                    .font(.system(size: 44, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.accentColor)

                Button {
                    showingDatePicker = true
                } label: {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(Color("textSecondary"))
                }
                .popover(isPresented: $showingDatePicker) {
                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .padding()
                        .frame(minWidth: 320, minHeight: 360)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 16)

            label("IZ RAČUNA")
            AccountPillPicker(accounts: accounts, selectedAccount: $fromAccount)
            if let fromAccount, amount > 0 {
                Text("Stanje po prenosu: \(euro(fromAccount.balance - amount))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color("textSecondary"))
                    .padding(.horizontal)
            }

            label("NA RAČUN")
            AccountPillPicker(
                accounts: accounts.filter { $0 != fromAccount },
                selectedAccount: $toAccount
            )
            if let toAccount, amount > 0 {
                Text("Stanje po prenosu: \(euro(toAccount.balance + amount))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color("textSecondary"))
                    .padding(.horizontal)
            }

            TextField("Opomba (neobvezno)", text: $note)
                .padding(12)
                .background(Color("cardBackground"))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)

            Text("Prenos se ne šteje med prilive, odlive ali budget.")
                .font(.caption)
                .foregroundStyle(Color("textSecondary"))
                .padding(.horizontal)

            Spacer()

            NumericKeypad(input: $amountInput)
        }
        .background(Color("appBackground"))
        .navigationTitle("Nov prenos")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if fromAccount == nil {
                fromAccount = accounts.first
            }
        }
        .onChange(of: fromAccount) { _, newValue in
            if newValue == toAccount {
                toAccount = nil
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Prekliči") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Shrani") { save() }
                    .disabled(!canSave)
            }
        }
    }

    private func save() {
        guard let fromAccount, let toAccount else { return }
        let transfer = AccountTransfer(date: date, amount: amount, note: note)
        modelContext.insert(transfer)
        transfer.fromAccount = fromAccount
        transfer.toAccount = toAccount
        dismiss()
    }
}
