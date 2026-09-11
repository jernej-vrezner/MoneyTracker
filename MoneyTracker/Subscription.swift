//
//  Subscription.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 11. 9. 2026.
//

import Foundation
import SwiftData


@Model

final class Subscription{
    var name: String = ""
    var amount: Decimal = 0
    var billingDay: Int = 1
    var category: Category? = nil
    var lastChargedMonth: Date =  Date.distantPast
    
    
    init(name:String,amount:Decimal,billingDay:Int,category:Category? = nil){
        self.name = name
        self.amount = amount
        self.billingDay = billingDay
        self.category = category
        self.lastChargedMonth = Date.distantPast
    }
}
