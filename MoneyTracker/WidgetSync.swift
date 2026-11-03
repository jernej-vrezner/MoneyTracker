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

        let expenses = transactions.filter {
            $0.type == .expense && $0.date >= month.start && $0.date < month.end
        }
        let spent = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        let limit = categories.reduce(Decimal(0)) { $0 + $1.monthlyLimit }

        let day = max(calendar.component(.day, from: now), 1)
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let projected = spent / Decimal(day) * Decimal(daysInMonth)

        var dailySpend = [Double](repeating: 0, count: day)
        for expense in expenses {
            let expenseDay = calendar.component(.day, from: expense.date)
            if expenseDay >= 1 && expenseDay <= day {
                dailySpend[expenseDay - 1] += double(expense.amount)
            }
        }

        let categorySnapshots = categories
            .map { category in
                CategorySnapshot(
                    name: category.name,
                    icon: category.icon,
                    colorName: category.color.rawValue,
                    spent: double(
                        expenses
                            .filter { $0.category == category }
                            .reduce(Decimal(0)) { $0 + $1.amount }
                    ),
                    limit: double(category.monthlyLimit)
                )
            }
            .sorted { $0.spent > $1.spent }

        let snapshot = WidgetSnapshot(
            budgetSpent: double(spent),
            budgetLimit: double(limit),
            projected: double(projected),
            dayOfMonth: day,
            daysInMonth: daysInMonth,
            dailySpend: dailySpend,
            todaySpent: dailySpend.last ?? 0,
            categories: Array(categorySnapshots.prefix(6)),
            goals: goals.prefix(3).map { goal in
                GoalSnapshot(
                    name: goal.name,
                    saved: double(goal.savedAmount),
                    target: double(goal.targetAmount),
                    deadline: goal.deadline
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
