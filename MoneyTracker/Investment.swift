//
//  Investment.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 12. 10. 2026.
//

import Foundation
import SwiftData

enum AssetKind: String, Codable, CaseIterable {
    case stock
    case etf
    case crypto

    var title: String {
        switch self {
        case .stock: return "Delnice"
        case .etf: return "ETF"
        case .crypto: return "Kripto"
        }
    }
}

@Model
final class Investment {
    var symbol: String = ""
    var name: String = ""
    var kind: AssetKind = AssetKind.stock
    var currency: String = "EUR"
    var lastPrice: Decimal? = nil
    var previousClose: Decimal? = nil
    var lastUpdated: Date? = nil

    @Relationship(deleteRule: .cascade, inverse: \InvestmentTrade.investment)
    var trades: [InvestmentTrade]? = []

    init(symbol: String, name: String, kind: AssetKind, currency: String) {
        self.symbol = symbol
        self.name = name
        self.kind = kind
        self.currency = currency
    }
}

@Model
final class InvestmentTrade {
    var date: Date = Date()
    var isBuy: Bool = true
    var quantity: Decimal = 0
    var totalAmount: Decimal = 0
    var investment: Investment? = nil

    init(date: Date, isBuy: Bool, quantity: Decimal, totalAmount: Decimal, investment: Investment? = nil) {
        self.date = date
        self.isBuy = isBuy
        self.quantity = quantity
        self.totalAmount = totalAmount
        self.investment = investment
    }
}
