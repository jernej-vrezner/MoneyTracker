//
//  Portfolio.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 12. 10. 2026.
//

import Foundation
import SwiftData
import SwiftUI

extension AssetKind {
    var color: Color {
        switch self {
        case .stock: return .teal
        case .etf: return .orange
        case .crypto: return .indigo
        }
    }

    var iconName: String {
        switch self {
        case .stock: return "chart.bar.fill"
        case .etf: return "chart.pie.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        }
    }
}

struct HoldingSummary: Identifiable {
    let investment: Investment
    let quantity: Decimal
    let costBasis: Decimal
    let priceEUR: Decimal
    let dayChangeEUR: Decimal
    let realized: Decimal

    var id: PersistentIdentifier { investment.persistentModelID }
    var value: Decimal { quantity * priceEUR }
    var profit: Decimal { value - costBasis }

    var profitPercent: Double? {
        guard costBasis > 0 else { return nil }
        return Double(truncating: (profit / costBasis) as NSNumber) * 100
    }
}

extension Investment {
    func summary(eurRate: Decimal) -> HoldingSummary {
        var quantity: Decimal = 0
        var cost: Decimal = 0
        var realized: Decimal = 0

        for trade in (trades ?? []).sorted(by: { $0.date < $1.date }) {
            if trade.isBuy {
                quantity += trade.quantity
                cost += trade.totalAmount
            } else if quantity > 0 {
                let average = cost / quantity
                let sold = min(trade.quantity, quantity)
                realized += trade.totalAmount - average * sold
                cost -= average * sold
                quantity -= sold
            }
        }

        let price = (lastPrice ?? 0) * eurRate
        let previous = (previousClose ?? lastPrice ?? 0) * eurRate
        return HoldingSummary(
            investment: self,
            quantity: quantity,
            costBasis: cost,
            priceEUR: price,
            dayChangeEUR: quantity * (price - previous),
            realized: realized
        )
    }
}

enum FXStore {
    static func decode(_ raw: String) -> [String: Decimal] {
        var result: [String: Decimal] = ["EUR": 1]
        for pair in raw.split(separator: ";") {
            let parts = pair.split(separator: "=")
            if parts.count == 2, let value = Decimal(string: String(parts[1])) {
                result[String(parts[0])] = value
            }
        }
        return result
    }

    static func encode(_ rates: [String: Decimal]) -> String {
        rates.map { "\($0.key)=\($0.value)" }.joined(separator: ";")
    }
}
