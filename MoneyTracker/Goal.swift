//
//  Goal.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//
import Foundation
import SwiftData
import SwiftUI


@Model

final class Goal{
    
    var name: String = ""
    var targetAmount: Decimal = 0
    var savedAmount: Decimal = 0
    var deadline: Date = Date()
    
    init(name: String, targetAmount: Decimal, savedAmount: Decimal, deadline: Date) {
        self.name = name
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
        self.deadline = deadline
    }
}

extension Goal {
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        return Double(truncating: (savedAmount / targetAmount) as NSNumber)
    }

    var remaining: Decimal {
        max(targetAmount - savedAmount, 0)
    }

    var monthlyNeeded: Decimal {
        let months = Calendar.current.dateComponents([.month], from: Date(), to: deadline).month ?? 0
        return remaining / Decimal(max(months, 1))
    }
}
    


