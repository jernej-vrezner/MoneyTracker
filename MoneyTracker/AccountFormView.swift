//
//  AccountFormView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 13. 10. 2026.
//

import SwiftUI
import SwiftData

struct AccountFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let accountToEdit: Account?
    let allowDelete: Bool

    @State private var name = ""
    @State private var kind: AccountKind = .bank
    @State private var balanceText = ""
    @State private var color: CategoryColor = .blue
    @State private var includeInTotal = true
    @State private var confirmDelete = false

    init(account: Account? = nil, allowDelete: Bool = true) {
        self.accountToEdit = account
        self.allowDelete = allowDelete
        if let account {
            _name = State(initialValue: account.name)
            _kind = State(initialValue: account.kind)
            _balanceText = State(initialValue: "\(account.initialBalance)".replacingOccurrences(of: ".", with: ","))
            _color = State(initialValue: account.color)
            _includeInTotal = State(initialValue: account.includeInTotal)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Color("textSecondary"))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: sectionTitle("IME")) {
                    TextField("Npr. NLB Tekoči", text: $name)
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: sectionTitle("VRSTA")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                        ForEach(AccountKind.allCases, id: \.self) { option in
                            Button {
                                kind = option
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: option.iconName)
                                    Text(option.title)
                                        .font(.caption)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(kind == option ? color.color.opacity(0.18) : Color("appBackground"))
                                .foregroundStyle(kind == option ? color.color : Color("textPrimary"))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(kind == option ? color.color : Color.clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: sectionTitle("ZAČETNO STANJE")) {
                    TextField("0,00 €", text: $balanceText)
                        .keyboardType(.decimalPad)
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: sectionTitle("BARVA")) {
                    LazyVGrid(columns: Array(repeating: GridItem(), count: 6), spacing: 14) {
                        ForEach(CategoryColor.allCases, id: \.self) { option in
                            Button {
                                color = option
                            } label: {
                                Circle()
                                    .fill(option.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color("textPrimary"), lineWidth: color == option ? 3 : 0)
                                            .padding(-4)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color("cardBackground"))

                Section(footer: Text("Izklopi za investicijske ali skupne račune, ki ne spadajo v tvoje osebno stanje.")) {
                    Toggle("Vključi v skupno stanje", isOn: $includeInTotal)
                }
                .listRowBackground(Color("cardBackground"))

                if accountToEdit != nil && allowDelete {
                    Section {
                        Button("Izbriši račun", role: .destructive) {
                            confirmDelete = true
                        }
                    }
                    .listRowBackground(Color("cardBackground"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
            .navigationTitle(accountToEdit == nil ? "Nov račun" : "Uredi račun")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Prekliči") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(accountToEdit == nil ? "Dodaj" : "Shrani") { save() }
                        .disabled(!canSave)
                }
            }
            .alert("Izbrišem račun?", isPresented: $confirmDelete) {
                Button("Izbriši", role: .destructive) {
                    if let accountToEdit {
                        modelContext.delete(accountToEdit)
                    }
                    dismiss()
                }
                Button("Prekliči", role: .cancel) {}
            } message: {
                Text("Transakcije tega računa ostanejo, a ne bodo več pripadale nobenemu računu. Prenosi z njim se izbrišejo.")
            }
        }
    }

    private func save() {
        let balance = Decimal(string: balanceText.replacingOccurrences(of: ",", with: ".")) ?? 0
        let trimmed = name.trimmingCharacters(in: .whitespaces)

        if let account = accountToEdit {
            account.name = trimmed
            account.kind = kind
            account.initialBalance = balance
            account.color = color
            account.includeInTotal = includeInTotal
        } else {
            let account = Account(name: trimmed, kind: kind, initialBalance: balance, color: color, includeInTotal: includeInTotal)
            modelContext.insert(account)
        }
        dismiss()
    }
}
