//
//  CategoryIconBadge.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 17. 9. 2026.
//

import SwiftUI

struct CategoryIconBadge: View {
    let icon: String
    let color: Color

    var body: some View {
        Image(systemName: icon)
            .foregroundStyle(color)
            .frame(width: 32, height: 32)
            .background(color.opacity(0.15))
            .clipShape(Circle())
    }
}
