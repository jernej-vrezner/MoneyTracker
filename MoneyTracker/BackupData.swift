//
//  BackupData.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 8. 10. 2026.
//

import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct BackupData: Codable {
    var version: Int
    var categories: [CategoryDTO]
    var subcategories: [SubcategoryDTO]
    var transactions: [TransactionDTO]
    var goals: [GoalDTO]
    var subscriptions: [SubscriptionDTO]
    var investments: [InvestmentDTO]?
    var investmentTrades: [TradeDTO]?
    var accounts: [AccountDTO]?
    var transfers: [AccountTransferDTO]?

    struct CategoryDTO: Codable {
        var id: Int
        var name: String
        var color: CategoryColor
        var monthlyLimit: String
        var icon: String
    }

    struct SubcategoryDTO: Codable {
        var id: Int
        var name: String
        var monthlyLimit: String?
        var categoryID: Int
    }

    struct TransactionDTO: Codable {
        var amount: String
        var date: Date
        var type: TransactioType
        var note: String
        var categoryID: Int?
        var subcategoryID: Int?
        var accountID: Int?
    }

    struct GoalDTO: Codable {
        var name: String
        var targetAmount: String
        var savedAmount: String
        var deadline: Date
    }

    struct SubscriptionDTO: Codable {
        var name: String
        var amount: String
        var billingDay: Int
        var note: String
        var lastChargedMonth: Date
        var categoryID: Int?
        var subcategoryID: Int?
        var accountID: Int?
    }
    
    struct InvestmentDTO: Codable {
        var id: Int
        var symbol: String
        var name: String
        var kind: AssetKind
        var currency: String
        var lastPrice: String?
        var previousClose: String?
        var lastUpdated: Date?
    }

    struct TradeDTO: Codable {
        var investmentID: Int
        var date: Date
        var isBuy: Bool
        var quantity: String
        var totalAmount: String
    }

    struct AccountDTO: Codable {
        var id: Int
        var name: String
        var kind: AccountKind
        var initialBalance: String
        var color: CategoryColor
        var includeInTotal: Bool
        var createdAt: Date
    }

    struct AccountTransferDTO: Codable {
        var date: Date
        var amount: String
        var note: String
        var fromAccountID: Int?
        var toAccountID: Int?
    }

    init(categories: [Category], transactions: [Transaction], goals: [Goal], subscriptions: [Subscription], investments: [Investment], accounts: [Account]) {
        var categoryIDs: [PersistentIdentifier: Int] = [:]
        var subcategoryIDs: [PersistentIdentifier: Int] = [:]
        var categoryDTOs: [CategoryDTO] = []
        var subcategoryDTOs: [SubcategoryDTO] = []

        for (index, category) in categories.enumerated() {
            categoryIDs[category.persistentModelID] = index
            categoryDTOs.append(CategoryDTO(
                id: index,
                name: category.name,
                color: category.color,
                monthlyLimit: "\(category.monthlyLimit)",
                icon: category.icon
            ))
            for sub in category.subcategories ?? [] {
                let subID = subcategoryDTOs.count
                subcategoryIDs[sub.persistentModelID] = subID
                subcategoryDTOs.append(SubcategoryDTO(
                    id: subID,
                    name: sub.name,
                    monthlyLimit: sub.monthlyLimit.map { "\($0)" },
                    categoryID: index
                ))
            }
        }

        var accountIDs: [PersistentIdentifier: Int] = [:]
        var accountDTOs: [AccountDTO] = []
        for (index, account) in accounts.enumerated() {
            accountIDs[account.persistentModelID] = index
            accountDTOs.append(AccountDTO(
                id: index,
                name: account.name,
                kind: account.kind,
                initialBalance: "\(account.initialBalance)",
                color: account.color,
                includeInTotal: account.includeInTotal,
                createdAt: account.createdAt
            ))
        }

        var transferDTOs: [AccountTransferDTO] = []
        for account in accounts {
            for transfer in account.outgoingTransfers ?? [] {
                transferDTOs.append(AccountTransferDTO(
                    date: transfer.date,
                    amount: "\(transfer.amount)",
                    note: transfer.note,
                    fromAccountID: transfer.fromAccount.flatMap { accountIDs[$0.persistentModelID] },
                    toAccountID: transfer.toAccount.flatMap { accountIDs[$0.persistentModelID] }
                ))
            }
        }

        self.version = 1
        self.categories = categoryDTOs
        self.subcategories = subcategoryDTOs
        self.transactions = transactions.map { t in
            TransactionDTO(
                amount: "\(t.amount)",
                date: t.date,
                type: t.type,
                note: t.note,
                categoryID: t.category.flatMap { categoryIDs[$0.persistentModelID] },
                subcategoryID: t.subcategory.flatMap { subcategoryIDs[$0.persistentModelID] },
                accountID: t.account.flatMap { accountIDs[$0.persistentModelID] }
            )
        }
        self.goals = goals.map { g in
            GoalDTO(
                name: g.name,
                targetAmount: "\(g.targetAmount)",
                savedAmount: "\(g.savedAmount)",
                deadline: g.deadline
            )
        }
        self.subscriptions = subscriptions.map { s in
            SubscriptionDTO(
                name: s.name,
                amount: "\(s.amount)",
                billingDay: s.billingDay,
                note: s.note,
                lastChargedMonth: s.lastChargedMonth,
                categoryID: s.category.flatMap { categoryIDs[$0.persistentModelID] },
                subcategoryID: s.subcategory.flatMap { subcategoryIDs[$0.persistentModelID] },
                accountID: s.account.flatMap { accountIDs[$0.persistentModelID] }
            )
        }
        var investmentDTOs: [InvestmentDTO] = []
        var tradeDTOs: [TradeDTO] = []
        for (index, investment) in investments.enumerated() {
            investmentDTOs.append(InvestmentDTO(
                id: index,
                symbol: investment.symbol,
                name: investment.name,
                kind: investment.kind,
                currency: investment.currency,
                lastPrice: investment.lastPrice.map { "\($0)" },
                previousClose: investment.previousClose.map { "\($0)" },
                lastUpdated: investment.lastUpdated
            ))
            for trade in investment.trades ?? [] {
                tradeDTOs.append(TradeDTO(
                    investmentID: index,
                    date: trade.date,
                    isBuy: trade.isBuy,
                    quantity: "\(trade.quantity)",
                    totalAmount: "\(trade.totalAmount)"
                ))
            }
        }
        self.investments = investmentDTOs
        self.investmentTrades = tradeDTOs
        self.accounts = accountDTOs
        self.transfers = transferDTOs
    }
}

struct BackupFile: Transferable {
    let data: BackupData

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { file in
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("MoneyTracker-backup.json")
            try encoder.encode(file.data).write(to: url)
            return SentTransferredFile(url)
        }
    }
}

extension BackupData {
    func restore(into context: ModelContext) throws {
        try context.delete(model: AccountTransfer.self)
        try context.delete(model: Account.self)
        try context.delete(model: InvestmentTrade.self)
        try context.delete(model: Investment.self)
        try context.delete(model: Transaction.self)
        try context.delete(model: Subscription.self)
        try context.delete(model: Goal.self)
        try context.delete(model: Subcategory.self)
        try context.delete(model: Category.self)

        var accountByID: [Int: Account] = [:]
        for dto in accounts ?? [] {
            let account = Account(
                name: dto.name,
                kind: dto.kind,
                initialBalance: Decimal(string: dto.initialBalance) ?? 0,
                color: dto.color,
                includeInTotal: dto.includeInTotal
            )
            account.createdAt = dto.createdAt
            context.insert(account)
            accountByID[dto.id] = account
        }

        var categoryByID: [Int: Category] = [:]
        for dto in categories {
            let category = Category(
                name: dto.name,
                color: dto.color,
                monthlyLimit: Decimal(string: dto.monthlyLimit) ?? 0,
                icon: dto.icon
            )
            context.insert(category)
            categoryByID[dto.id] = category
        }

        var subcategoryByID: [Int: Subcategory] = [:]
        for dto in subcategories {
            let sub = Subcategory(
                name: dto.name,
                monthlyLimit: dto.monthlyLimit.flatMap { Decimal(string: $0) },
                parent: categoryByID[dto.categoryID]
            )
            context.insert(sub)
            subcategoryByID[dto.id] = sub
        }

        for dto in transactions {
            let transaction = Transaction(
                amount: Decimal(string: dto.amount) ?? 0,
                date: dto.date,
                type: dto.type,
                note: dto.note,
                category: dto.categoryID.flatMap { categoryByID[$0] }
            )
            context.insert(transaction)
            transaction.subcategory = dto.subcategoryID.flatMap { subcategoryByID[$0] }
            transaction.account = dto.accountID.flatMap { accountByID[$0] }
        }

        for dto in transfers ?? [] {
            let transfer = AccountTransfer(
                date: dto.date,
                amount: Decimal(string: dto.amount) ?? 0,
                note: dto.note
            )
            context.insert(transfer)
            transfer.fromAccount = dto.fromAccountID.flatMap { accountByID[$0] }
            transfer.toAccount = dto.toAccountID.flatMap { accountByID[$0] }
        }

        for dto in goals {
            context.insert(Goal(
                name: dto.name,
                targetAmount: Decimal(string: dto.targetAmount) ?? 0,
                savedAmount: Decimal(string: dto.savedAmount) ?? 0,
                deadline: dto.deadline
            ))
        }

        for dto in subscriptions {
            let subscription = Subscription(
                name: dto.name,
                amount: Decimal(string: dto.amount) ?? 0,
                billingDay: dto.billingDay,
                category: dto.categoryID.flatMap { categoryByID[$0] }
            )
            context.insert(subscription)
            subscription.subcategory = dto.subcategoryID.flatMap { subcategoryByID[$0] }
            subscription.account = dto.accountID.flatMap { accountByID[$0] }
            subscription.note = dto.note
            subscription.lastChargedMonth = dto.lastChargedMonth
        }

        var investmentByID: [Int: Investment] = [:]
        for dto in investments ?? [] {
            let investment = Investment(symbol: dto.symbol, name: dto.name, kind: dto.kind, currency: dto.currency)
            investment.lastPrice = dto.lastPrice.flatMap { Decimal(string: $0) }
            investment.previousClose = dto.previousClose.flatMap { Decimal(string: $0) }
            investment.lastUpdated = dto.lastUpdated
            context.insert(investment)
            investmentByID[dto.id] = investment
        }

        for dto in investmentTrades ?? [] {
            let trade = InvestmentTrade(
                date: dto.date,
                isBuy: dto.isBuy,
                quantity: Decimal(string: dto.quantity) ?? 0,
                totalAmount: Decimal(string: dto.totalAmount) ?? 0
            )
            context.insert(trade)
            trade.investment = investmentByID[dto.investmentID]
        }

        try context.save()
    }
}
