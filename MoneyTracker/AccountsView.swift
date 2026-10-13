//
//  AccountsView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 13. 10. 2026.
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @State private var showingNew = false
    @State private var accountToEdit: Account? = nil
    @State private var showingTransfer = false

    private let groups: [(title: String, kinds: [AccountKind])] = [
        ("TEKOČI IN KARTICE", [.bank, .card, .credit]),
        ("GOTOVINA", [.cash]),
        ("VARČEVANJE", [.savings]),
        ("INVESTICIJSKI", [.investment])
    ]

    private var countedAccounts: [Account] {
        accounts.filter { $0.includeInTotal }
    }

    private var totalBalance: Decimal {
        countedAccounts.reduce(Decimal(0)) { $0 + $1.balance }
    }

    private var positiveTotal: Decimal {
        countedAccounts.filter { $0.balance > 0 }.reduce(Decimal(0)) { $0 + $1.balance }
    }

    private func euro(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR"))
    }

    private func fraction(of account: Account) -> Double {
        guard positiveTotal > 0 else { return 0 }
        return Double(truncating: (account.balance / positiveTotal) as NSNumber)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                totalCard

                ForEach(groups, id: \.title) { group in
                    let groupAccounts = accounts.filter { group.kinds.contains($0.kind) }
                    if !groupAccounts.isEmpty {
                        groupCard(title: group.title, accounts: groupAccounts)
                    }
                }

                Button {
                    showingNew = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Nov račun", systemImage: "plus")
                            .foregroundStyle(Color("textSecondary"))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .cardStyle()
                }
                .buttonStyle(.plain)

                Text("Investicijski računi se ne štejejo v skupno stanje, če imaš izklopljeno možnost pri računu.")
                    .font(.caption)
                    .foregroundStyle(Color("textSecondary"))
            }
            .padding()
        }
        .background(Color("appBackground"))
        .navigationTitle("Računi")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingNew) {
            AccountFormView()
        }
        .sheet(item: $accountToEdit) { account in
            AccountFormView(account: account)
        }
        .sheet(isPresented: $showingTransfer) {
            TransferView()
        }
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SKUPNO STANJE")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("textSecondary"))

            Text(euro(totalBalance))
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(Color("textPrimary"))

            if positiveTotal > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(countedAccounts.filter { $0.balance > 0 }) { account in
                            Rectangle()
                                .fill(account.color.color)
                                .frame(width: geometry.size.width * fraction(of: account))
                        }
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
            }

            if accounts.count >= 2 {
                Button {
                    showingTransfer = true
                } label: {
                    Label("Prenos med računi", systemImage: "arrow.left.arrow.right")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color("textPrimary"))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private func groupCard(title: String, accounts: [Account]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(title)
                Spacer()
                Text(euro(accounts.reduce(Decimal(0)) { $0 + $1.balance }))
            }
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Color("textSecondary"))
            .padding(.bottom, 8)

            ForEach(accounts) { account in
                NavigationLink {
                    AccountDetailView(account: account)
                } label: {
                    accountRow(account)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button {
                        accountToEdit = account
                    } label: {
                        Label("Uredi račun", systemImage: "pencil")
                    }
                }
                if account.id != accounts.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func accountRow(_ account: Account) -> some View {
        HStack(spacing: 12) {
            CategoryIconBadge(icon: account.kind.iconName, color: account.color.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("textPrimary"))
                Text("\(account.kind.title) · \((account.transactions ?? []).count) transakcij")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color("textSecondary"))
            }

            Spacer()

            Text(euro(account.balance))
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(account.balance < 0 ? Color("negativeColor") : Color("textPrimary"))
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }
}
