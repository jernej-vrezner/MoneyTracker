//
//  Category.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//

import Foundation
import SwiftData
import SwiftUI

enum CategoryColor: String,Codable,CaseIterable {
    case red,blue,green,orange,purple,yellow
}

@Model
final class Category {
    var name: String = ""
    var color: CategoryColor = CategoryColor.red
    var monthlyLimit: Decimal = 0
    
    
    init(name: String, color: CategoryColor, monthlyLimit: Decimal) {
        self.name = name
        self.color = color
        self.monthlyLimit = monthlyLimit
    }
}
extension CategoryColor {
    var color: Color {
        switch self {
        case .red: return .red
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .purple: return .purple
        case .yellow: return .yellow
        }
    }
}
