//
//  AccountDetailView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 13. 10. 2026.
//

import SwiftUI
import SwiftData

enum AccountEntry: Identifiable {
    case transaction(Transaction)
    case transfer(AccountTransfer, outgoing: Bool)

    var id: String {
        switch self {
        case .transaction(let transaction):
            return "t-\(transaction.persistentModelID.hashValue)"
        case .transfer(let transfer, let outgoing):
            return "x-\(transfer.persistentModelID.hashValue)-\(outgoing)"
        }
    }

    var date: Date {
        switch self {
        case .transaction(let transaction): return transaction.date
        case .transfer(let transfer, _): return transfer.date
        }
    }
}

struct AccountDetailView: View {
    let account: Account

    @Environment(\.modelContext) private var modelContext
    @State private var showingEdit = false
    @State private var transactionToEdit: Transaction? = nil

    private var entries: [AccountEntry] {
        var result: [AccountEntry] = []
        for transaction in account.transactions ?? [] {
            result.append(.transaction(transaction))
        }
        for transfer in account.outgoingTransfers ?? [] {
            result.append(.transfer(transfer, outgoing: true))
        }
        for transfer in account.incomingTransfers ?? [] {
            result.append(.transfer(transfer, outgoing: false))
        }
        return result.sorted { $0.date > $1.date }
    }

    private var monthlyGroups: [(month: Date, items: [AccountEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: entries) { entry in
            calendar.dateInterval(of: .month, for: entry.date)?.start ?? entry.date
        }
        return grouped
            .map { (month: $0.key, items: $0.value) }
            .sorted { $0.month > $1.month }
    }

    private var thisMonthEntries: [AccountEntry] {
        entries.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    private var monthIncome: Decimal {
        thisMonthEntries.reduce(Decimal(0)) { sum, entry in
            if case .transaction(let transaction) = entry, transaction.type == .income {
                return sum + transaction.amount
            }
            return sum
        }
    }

    private var monthExpense: Decimal {
        thisMonthEntries.reduce(Decimal(0)) { sum, entry in
            if case .transaction(let transaction) = entry, transaction.type != .income {
                return sum + transaction.amount
            }
            return sum
        }
    }

    private var monthTransfers: Decimal {
        thisMonthEntries.reduce(Decimal(0)) { sum, entry in
            if case .transfer(let transfer, let outgoing) = entry {
                return sum + (outgoing ? -transfer.amount : transfer.amount)
            }
            return sum
        }
    }

    private func euro(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR"))
    }

    private func shortDate(_ date: Date) -> String {
        let calendar = Calendar.current
        return "\(calendar.component(.day, from: date)). \(calendar.component(.month, from: date))."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header
                balanceCard
                statsRow

                if entries.isEmpty {
                    Text("Na tem računu še ni transakcij.")
                        .font(.caption)
                        .foregroundStyle(Color("textSecondary"))
                } else {
                    ForEach(monthlyGroups, id: \.month) { group in
                        monthCard(group)
                    }
                }
            }
            .padding()
        }
        .background(Color("appBackground"))
        .navigationTitle("Račun")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Uredi") { showingEdit = true }
            }
        }
        .sheet(isPresented: $showingEdit) {
            AccountFormView(account: account, allowDelete: false)
        }
        .sheet(item: $transactionToEdit) { transaction in
            AddTransactionView(transaction: transaction)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: account.kind.iconName)
                .font(.title3)
                .foregroundStyle(account.color.color)
                .frame(width: 48, height: 48)
                .background(account.color.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Color("textPrimary"))
                Text(account.kind.title)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color("textSecondary"))
            }
        }
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("STANJE")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("textSecondary"))
            Text(euro(account.balance))
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(account.balance < 0 ? Color("negativeColor") : Color("textPrimary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            StatTile(label: "PRILIVI", value: "+" + euro(monthIncome), color: Color("positiveColor"))
            StatTile(label: "ODLIVI", value: "-" + euro(monthExpense), color: Color("negativeColor"))
            StatTile(
                label: "PRENOSI",
                value: (monthTransfers >= 0 ? "+" : "") + euro(monthTransfers),
                color: Color.accentColor
            )
        }
    }

    private func monthCard(_ group: (month: Date, items: [AccountEntry])) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.month.formatted(.dateTime.month(.wide).year()).uppercased())
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("textSecondary"))
                .padding(.bottom, 8)

            ForEach(group.items) { entry in
                row(entry)
                if entry.id != group.items.last?.id {
                    Divider()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    @ViewBuilder
    private func row(_ entry: AccountEntry) -> some View {
        switch entry {
        case .transaction(let transaction):
            HStack(spacing: 12) {
                CategoryIconBadge(
                    icon: transaction.category?.icon ?? "questionmark.circle",
                    color: transaction.category?.color.color ?? Color("textSecondary")
                )
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.note.isEmpty ? (transaction.category?.name ?? "Brez kategorije") : transaction.note)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color("textPrimary"))
                        .lineLimit(1)
                    Text((transaction.category?.name ?? "Brez kategorije")
                         + (transaction.subcategory.map { " › " + $0.name } ?? "")
                         + " · " + shortDate(transaction.date))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color("textSecondary"))
                        .lineLimit(1)
                }
                Spacer()
                Text((transaction.type == .income ? "+" : "-") + euro(transaction.amount))
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(transaction.type == .income ? Color("positiveColor") : Color("negativeColor"))
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
            .onTapGesture { transactionToEdit = transaction }
            .contextMenu {
                Button(role: .destructive) {
                    modelContext.delete(transaction)
                } label: {
                    Label("Izbriši transakcijo", systemImage: "trash")
                }
            }

        case .transfer(let transfer, let outgoing):
            HStack(spacing: 12) {
                Image(systemName: "arrow.left.arrow.right")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(transfer.note.isEmpty ? "Prenos" : transfer.note)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color("textPrimary"))
                        .lineLimit(1)
                    Text((outgoing ? "na \(transfer.toAccount?.name ?? "?")" : "iz \(transfer.fromAccount?.name ?? "?")")
                         + " · " + shortDate(transfer.date))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color("textSecondary"))
                        .lineLimit(1)
                }
                Spacer()
                Text((outgoing ? "-" : "+") + euro(transfer.amount))
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .padding(.vertical, 10)
            .contextMenu {
                Button(role: .destructive) {
                    modelContext.delete(transfer)
                } label: {
                    Label("Izbriši prenos", systemImage: "trash")
                }
            }
        }
    }
}
