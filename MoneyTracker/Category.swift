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
    case red,blue,green,orange,purple,yellow,pink,teal,indigo,mint,cyan,brown
}

@Model
final class Category {
    var name: String = ""
    var color: CategoryColor = CategoryColor.red
    var monthlyLimit: Decimal = 0
    var icon: String = "tag.fill"
    @Relationship(deleteRule: .cascade, inverse: \Subcategory.parent)
    var subcategories: [Subcategory]? = []
    
    
    static let iconOptions = [
        "fork.knife", "car.fill", "bag.fill", "house.fill", "gamecontroller.fill",
        "heart.fill", "airplane", "creditcard.fill", "gift.fill", "tag.fill",
        "cart.fill", "bolt.fill", "drop.fill", "pawprint.fill", "graduationcap.fill",
        "cross.case.fill", "tram.fill", "fuelpump.fill", "tshirt.fill", "music.note",
        "book.fill", "dumbbell.fill", "cup.and.saucer.fill", "briefcase.fill", "wrench.and.screwdriver.fill"
    ]

    init(name: String, color: CategoryColor, monthlyLimit: Decimal,icon:String) {
        self.name = name
        self.color = color
        self.monthlyLimit = monthlyLimit
        self.icon = icon
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
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        case .mint: return .mint
        case .cyan: return .cyan
        case .brown: return .brown
        }
    }
}
