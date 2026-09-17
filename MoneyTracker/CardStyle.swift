//
//  CardStyle.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 16. 9. 2026.
//

import SwiftUI

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color("cardBackground"))
            .cornerRadius(24)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

struct PillStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
    }
}

extension View {
    func pillStyle() -> some View {
        modifier(PillStyle())
    }
}
