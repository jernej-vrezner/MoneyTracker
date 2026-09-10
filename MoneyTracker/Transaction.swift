//
//  Transaction.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 9. 9. 2026.
//
import Foundation
import SwiftData

enum TransactioType: String, Codable, CaseIterable {
    case income
    case expense
    case investment
}

@Model
final class Transaction {
    
    var amount: Decimal = 0
    var date: Date = Date()
    var type: TransactioType = TransactioType.expense
    var note: String = ""
    
    init(amount: Decimal, date: Date, type: TransactioType, note: String) {
        self.amount = amount
        self.date = date
        self.type = type
        self.note = note
    }
}
