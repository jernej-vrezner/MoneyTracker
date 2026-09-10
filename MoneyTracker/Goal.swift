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
    
    


