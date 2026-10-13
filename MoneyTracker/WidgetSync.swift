//
//  WidgetSync.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 13. 10. 2026.
//

import Foundation
import SwiftData
import WidgetKit

enum WidgetSync {
    static func update(context: ModelContext) {
        let calendar = Calendar.current
        let now = Date()
        guard let month = calendar.dateInterval(of: .month, for: now) else { return }

        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        let categories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let goals = (try? context.fetch(FetchDescriptor<Goal>(sortBy: [SortDescriptor(\.deadline)]))) ?? []

        let spent = transactions
            .filter { $0.type == .expense && $0.date >= month.start && $0.date < month.end }
            .reduce(Decimal(0)) { $0 + $1.amount }
        let limit = categories.reduce(Decimal(0)) { $0 + $1.monthlyLimit }

        let day = max(calendar.component(.day, from: now), 1)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let projected = spent / Decimal(day) * Decimal(daysInMonth)

        let snapshot = WidgetSnapshot(
            budgetSpent: double(spent),
            budgetLimit: double(limit),
            projected: double(projected),
            goals: goals.prefix(3).map { goal in
                GoalSnapshot(
                    name: goal.name,
                    saved: double(goal.savedAmount),
                    target: double(goal.targetAmount)
                )
            },
            updatedAt: now
        )
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func double(_ value: Decimal) -> Double {
        Double(truncating: value as NSNumber)
    }
}
