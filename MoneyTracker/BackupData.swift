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
    }

    init(categories: [Category], transactions: [Transaction], goals: [Goal], subscriptions: [Subscription]) {
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
                subcategoryID: t.subcategory.flatMap { subcategoryIDs[$0.persistentModelID] }
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
                subcategoryID: s.subcategory.flatMap { subcategoryIDs[$0.persistentModelID] }
            )
        }
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
        try context.delete(model: Transaction.self)
        try context.delete(model: Subscription.self)
        try context.delete(model: Goal.self)
        try context.delete(model: Subcategory.self)
        try context.delete(model: Category.self)

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
            subscription.note = dto.note
            subscription.lastChargedMonth = dto.lastChargedMonth
        }

        try context.save()
    }
}
