//
//  Account.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 13. 10. 2026.
//

import Foundation
import SwiftData

enum AccountKind: String, Codable, CaseIterable {
    case bank
    case card
    case cash
    case savings
    case credit
    case investment

    var title: String {
        switch self {
        case .bank: return "Bančni"
        case .card: return "Kartica"
        case .cash: return "Gotovina"
        case .savings: return "Varčevalni"
        case .credit: return "Kreditna"
        case .investment: return "Investicijski"
        }
    }

    var iconName: String {
        switch self {
        case .bank: return "building.columns.fill"
        case .card: return "creditcard.fill"
        case .cash: return "banknote.fill"
        case .savings: return "leaf.fill"
        case .credit: return "creditcard.trianglebadge.exclamationmark"
        case .investment: return "chart.bar.fill"
        }
    }
}

@Model
final class Account {
    var name: String = ""
    var kind: AccountKind = AccountKind.bank
    var initialBalance: Decimal = 0
    var color: CategoryColor = CategoryColor.blue
    var includeInTotal: Bool = true
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    var transactions: [Transaction]? = []

    @Relationship(deleteRule: .cascade, inverse: \AccountTransfer.fromAccount)
    var outgoingTransfers: [AccountTransfer]? = []

    @Relationship(deleteRule: .cascade, inverse: \AccountTransfer.toAccount)
    var incomingTransfers: [AccountTransfer]? = []

    init(name: String, kind: AccountKind, initialBalance: Decimal, color: CategoryColor, includeInTotal: Bool = true) {
        self.name = name
        self.kind = kind
        self.initialBalance = initialBalance
        self.color = color
        self.includeInTotal = includeInTotal
    }

    var balance: Decimal {
        var total = initialBalance
        for transaction in transactions ?? [] {
            switch transaction.type {
            case .income: total += transaction.amount
            case .expense, .investment: total -= transaction.amount
            }
        }
        for transfer in incomingTransfers ?? [] { total += transfer.amount }
        for transfer in outgoingTransfers ?? [] { total -= transfer.amount }
        return total
    }
}

@Model
final class AccountTransfer {
    var date: Date = Date()
    var amount: Decimal = 0
    var note: String = ""
    var fromAccount: Account? = nil
    var toAccount: Account? = nil

    init(date: Date, amount: Decimal, note: String = "", fromAccount: Account? = nil, toAccount: Account? = nil) {
        self.date = date
        self.amount = amount
        self.note = note
        self.fromAccount = fromAccount
        self.toAccount = toAccount
    }
}
