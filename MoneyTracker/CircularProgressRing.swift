//
//  CircularProgressRing.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 23. 9. 2026.
//

import SwiftUI

struct CircularProgressRing: View {
    let progress: Double
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("textSecondary").opacity(0.2), lineWidth: 8)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%")
                .font(.system(.caption, design: .monospaced).weight(.bold))
                .foregroundStyle(Color("textPrimary"))
        }
        .frame(width: 64, height: 64)
    }
}
