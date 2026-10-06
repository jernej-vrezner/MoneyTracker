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

        let calendar = Calendar.current
        let today = Date()
        let startOfThisMonth = calendar.dateInterval(of: .month, for: today)!.start
        let todayDay = calendar.component(.day, from: today)

        for monthOffset in 0..<12 {
            let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: startOfThisMonth)!
            let daysInMonth = calendar.range(of: .day, in: .month, for: monthStart)!.count
            let maxDay = monthOffset == 0 ? todayDay : daysInMonth

            let salary = Decimal(Int.random(in: 2200...2700))
            let salaryDate = calendar.date(byAdding: .hour, value: 12, to: monthStart)!
            if monthOffset > 0 || todayDay >= 1 {
                context.insert(Transaction(amount: salary, date: salaryDate, type: .income, note: "Plača", category: nil))
            }

            for _ in 0..<10 {
                guard let category = categories.randomElement() else { continue }
                let day = Int.random(in: 1...maxDay)
                let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthStart)!
                let date = calendar.date(byAdding: .hour, value: 12, to: dayDate)!
                let amount = Decimal(Int.random(in: 500...9000)) / 100
                let note = merchants[category.name]?.randomElement() ?? ""
                let transaction = Transaction(amount: amount, date: date, type: .expense, note: note, category: category)
                context.insert(transaction)
                if let subs = category.subcategories, let sub = subs.randomElement() {
                    transaction.subcategory = sub
                }
            }
        }
    }
}
#endif
