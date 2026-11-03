//
//  WidgetSnapshot.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 13. 10. 2026.
//

import Foundation

struct GoalSnapshot: Codable, Identifiable {
    var name: String
    var saved: Double
    var target: Double
    var deadline: Date

    var id: String { name }

    var progress: Double {
        guard target > 0 else { return 0 }
        return min(saved / target, 1)
    }
}

struct CategorySnapshot: Codable, Identifiable {
    var name: String
    var icon: String
    var colorName: String
    var spent: Double
    var limit: Double

    var id: String { name }
}

struct WidgetSnapshot: Codable {
    var budgetSpent: Double
    var budgetLimit: Double
    var projected: Double
    var dayOfMonth: Int
    var daysInMonth: Int
    var dailySpend: [Double]
    var todaySpent: Double
    var categories: [CategorySnapshot]
    var goals: [GoalSnapshot]
    var updatedAt: Date

    static let groupID = "group.name.jernejvrezner.MoneyTracker"
    static let storageKey = "widgetSnapshot"

    static var empty: WidgetSnapshot {
        WidgetSnapshot(
            budgetSpent: 0,
            budgetLimit: 0,
            projected: 0,
            dayOfMonth: 1,
            daysInMonth: 30,
            dailySpend: [],
            todaySpent: 0,
            categories: [],
            goals: [],
            updatedAt: Date()
        )
    }

    static func load() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: groupID),
              let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: WidgetSnapshot.groupID),
              let data = try? JSONEncoder().encode(self) else {
            return
        }
        defaults.set(data, forKey: WidgetSnapshot.storageKey)
    }
}
