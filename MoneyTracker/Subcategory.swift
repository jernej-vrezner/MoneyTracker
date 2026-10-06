//
//  Subcategory.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 6. 10. 2026.
//

import Foundation
import SwiftData

@Model
final class Subcategory{
    var name: String = ""
    var monthlyLimit: Decimal? = nil
    var parent: Category? = nil
    
    init(name: String, monthlyLimit: Decimal? = nil, parent: Category? = nil) {
           self.name = name
           self.monthlyLimit = monthlyLimit
           self.parent = parent
       }
}
