//
//  CategoryProgressBar.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 17. 9. 2026.
//

import SwiftUI

struct CategoryProgressBar: View {
    let progress: Double
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color("textSecondary").opacity(0.2))
                Capsule()
                    .fill(color)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
            }
        }
        .frame(height: 8)
    }
}
