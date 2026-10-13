//
//  TestData.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 6. 10. 2026.
//

#if DEBUG
import Foundation
import SwiftData

enum TestData {
    private static let merchants: [String: [String]] = [
        "Hrana": ["Mercator", "Lidl", "Spar", "Restavracija"],
        "Dom": ["Elektrika", "Voda", "Zavarovalnica", "Najemnina"],
        "Prevoz": ["Petrol", "Avtobus", "Parkirnina"],
        "Avto": ["Petrol", "Servis", "Parkirnina"],
        "Zabava": ["Kino", "Netflix", "Koncert"],
        "Nakupovanje": ["Zara", "H&M", "Amazon"]
    ]

    static func reset(in context: ModelContext, categories: [Category]) {
        try? context.delete(model: Transaction.self)
        try? context.delete(model: AccountTransfer.self)
        try? context.delete(model: Account.self)
        seed(in: context, categories: categories)
    }

    static func seed(in context: ModelContext, categories existing: [Category]) {
        var categories = existing
        if categories.isEmpty {
            let defaults: [(String, CategoryColor, String, Decimal)] = [
                ("Hrana", .red, "fork.knife", 300),
                ("Dom", .blue, "house.fill", 700),
                ("Prevoz", .teal, "car.fill", 150),
                ("Zabava", .purple, "gamecontroller.fill", 100),
                ("Nakupovanje", .pink, "bag.fill", 150)
            ]
            for (name, color, icon, limit) in defaults {
                let category = Category(name: name, color: color, monthlyLimit: limit, icon: icon)
                context.insert(category)
                categories.append(category)
            }
        }

        var accounts = (try? context.fetch(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.createdAt)]))) ?? []
        if accounts.isEmpty {
            let defaults: [(String, AccountKind, Decimal, CategoryColor)] = [
                ("NLB Tekoči", .bank, 1500, .blue),
                ("Revolut", .card, 300, .indigo),
                ("Gotovina", .cash, 150, .orange),
                ("Varčevalni", .savings, 3000, .green)
            ]
            for (name, kind, balance, color) in defaults {
                let account = Account(name: name, kind: kind, initialBalance: balance, color: color)
                context.insert(account)
                accounts.append(account)
            }
        }

        let main = accounts.first { $0.kind == .bank } ?? accounts.first
        let card = accounts.first { $0.kind == .card }
        let cash = accounts.first { $0.kind == .cash }
        let savings = accounts.first { $0.kind == .savings }

        func spendingAccount() -> Account? {
            let roll = Int.random(in: 1...100)
            if roll <= 70 { return main }
            if roll <= 85 { return card ?? main }
            return cash ?? main
        }

        let calendar = Calendar.current
        let today = Date()
        let startOfThisMonth = calendar.dateInterval(of: .month, for: today)!.start
        let todayDay = calendar.component(.day, from: today)

        for monthOffset in 0..<12 {
            let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: startOfThisMonth)!
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
            let maxDay = monthOffset == 0 ? todayDay : daysInMonth

            func date(day: Int) -> Date {
                let dayDate = calendar.date(byAdding: .day, value: min(day, maxDay) - 1, to: monthStart)!
                return calendar.date(byAdding: .hour, value: 12, to: dayDate)!
            }

            let salary = Decimal(Int.random(in: 2200...2700))
            let salaryTransaction = Transaction(amount: salary, date: date(day: 1), type: .income, note: "Plača", category: nil)
            context.insert(salaryTransaction)
            salaryTransaction.account = main

            for _ in 0..<10 {
                guard let category = categories.randomElement() else { continue }
                let amount = Decimal(Int.random(in: 500...9000)) / 100
                let note = merchants[category.name]?.randomElement() ?? ""
                let transaction = Transaction(
                    amount: amount,
                    date: date(day: Int.random(in: 1...maxDay)),
                    type: .expense,
                    note: note,
                    category: category
                )
                context.insert(transaction)
                if let subs = category.subcategories, let sub = subs.randomElement() {
                    transaction.subcategory = sub
                }
                transaction.account = spendingAccount()
            }

            func addTransfer(_ amount: Decimal, note: String, day: Int, from: Account?, to: Account?) {
                guard let from, let to, from !== to else { return }
                let transfer = AccountTransfer(date: date(day: day), amount: amount, note: note)
                context.insert(transfer)
                transfer.fromAccount = from
                transfer.toAccount = to
            }

            addTransfer(200, note: "Varčevanje", day: 2, from: main, to: savings)
            addTransfer(100, note: "Dvig na bankomatu", day: 5, from: main, to: cash)
            addTransfer(150, note: "Polnjenje Revolut", day: 3, from: main, to: card)
        }
    }
}
#endif
