//
//  PortfolioHistory.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 14. 10. 2026.
//

import Foundation

struct PortfolioPoint: Identifiable {
    let date: Date
    let value: Double
    var id: Date { date }
}

struct HoldingInput {
    let symbol: String
    let currency: String
    let trades: [(date: Date, quantity: Decimal)]
}

enum PortfolioHistory {
    static func build(
        holdings: [HoldingInput],
        range: PriceRange,
        rates: [String: Decimal]
    ) async -> [PortfolioPoint] {
        var histories: [[PricePoint]] = []
        for holding in holdings {
            let points = (try? await YahooFinance.history(symbol: holding.symbol, range: range)) ?? []
            histories.append(points.sorted { $0.date < $1.date })
        }

        var dateSet = Set<Date>()
        for points in histories {
            for point in points {
                dateSet.insert(point.date)
            }
        }
        let dates = dateSet.sorted()
        guard !dates.isEmpty else { return [] }

        var cursors = [Int](repeating: 0, count: holdings.count)
        var lastPrices = [Double?](repeating: nil, count: holdings.count)
        var result: [PortfolioPoint] = []

        for date in dates {
            var total = 0.0
            for index in holdings.indices {
                let points = histories[index]
                while cursors[index] < points.count, points[cursors[index]].date <= date {
                    lastPrices[index] = points[cursors[index]].close
                    cursors[index] += 1
                }
                guard let price = lastPrices[index] else { continue }

                var quantity: Decimal = 0
                for trade in holdings[index].trades where trade.date <= date {
                    quantity += trade.quantity
                }
                guard quantity > 0 else { continue }

                let currency = holdings[index].currency
                let rate = rates[currency] ?? (currency == "EUR" ? 1 : 0)
                total += Double(truncating: quantity as NSNumber) * price * Double(truncating: rate as NSNumber)
            }
            result.append(PortfolioPoint(date: date, value: total))
        }

        return Array(result.drop { $0.value == 0 })
    }
}
