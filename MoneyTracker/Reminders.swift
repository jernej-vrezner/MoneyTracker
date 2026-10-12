//
//  Reminders.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 12. 10. 2026.
//

import Foundation
import SwiftData
import UserNotifications

enum Reminders {
    private static let dailyID = "daily-reminder"
    private static let subscriptionPrefix = "subscription-"

    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    static func applyDailyReminder(enabled: Bool, minutes: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyID])
        guard enabled else { return }

        let content = UNMutableNotificationContent()
        content.title = "MoneyTracker"
        content.body = "Si danes vnesel stroške?"
        content.sound = .default

        var components = DateComponents()
        components.hour = minutes / 60
        components.minute = minutes % 60
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        center.add(UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger))
    }

    static func applySubscriptionReminders(enabled: Bool, subscriptions: [Subscription]) async {
        let items = subscriptions.map { subscription in
            (
                name: subscription.name,
                amount: subscription.amount.formatted(.currency(code: "EUR")),
                day: subscription.billingDay
            )
        }

        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let old = pending.map(\.identifier).filter { $0.hasPrefix(subscriptionPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: old)
        guard enabled else { return }

        for (index, item) in items.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Naročnina"
            content.body = "\(item.name) (\(item.amount)) se obračuna \(item.day). v mesecu."
            content.sound = .default

            var components = DateComponents()
            components.day = max(1, min(item.day - 1, 28))
            components.hour = 9
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "\(subscriptionPrefix)\(index)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }
}
