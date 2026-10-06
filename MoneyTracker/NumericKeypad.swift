//
//  NumericKeypad.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 23. 9. 2026.
//

import SwiftUI

struct NumericKeypad: View {
    @Binding var input: String

    private let rows: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "⌫"]
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            handleTap(key)
                        } label: {
                            Text(key)
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color("cardBackground"))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color("textSecondary").opacity(0.25), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom)
    }

    private func handleTap(_ key: String) {
        switch key {
        case "⌫":
            if input.count > 1 {
                input.removeLast()
            } else {
                input = "0"
            }
        case ".":
            if !input.contains(".") {
                input += "."
            }
        default:
            if input == "0" {
                input = key
            } else {
                input += key
            }
        }
    }
}
