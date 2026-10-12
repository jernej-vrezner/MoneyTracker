//
//  SavingsView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 12. 10. 2026.
//

import SwiftUI

struct SavingsView: View {
    enum Mode: String, CaseIterable {
        case goals = "Cilji"
        case investments = "Naložbe"
    }

    @State private var mode: Mode = .goals

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Varčevanje")

            Picker("Prikaz", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.bottom, 8)

            switch mode {
            case .goals:
                GoalsView()
            case .investments:
                InvestmentsView()
            }
        }
        .background(Color("appBackground"))
    }
}
