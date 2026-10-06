//
//  CategoryAppearancePicker.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 6. 10. 2026.
//

import SwiftUI

struct CategoryAppearancePicker: View {
    @Binding var color: CategoryColor
    @Binding var icon: String

    var body: some View {
        Section(header: Text("BARVA").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 6), spacing: 14) {
                ForEach(CategoryColor.allCases, id: \.self) { c in
                    Button {
                        color = c
                    } label: {
                        Circle()
                            .fill(c.color)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .stroke(Color("textPrimary"), lineWidth: color == c ? 3 : 0)
                                    .padding(-4)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(Color("cardBackground"))

        Section(header: Text("IKONA").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
            LazyVGrid(columns: Array(repeating: GridItem(), count: 5), spacing: 10) {
                ForEach(Category.iconOptions, id: \.self) { option in
                    Button {
                        icon = option
                    } label: {
                        Image(systemName: option)
                            .font(.title2)
                            .frame(width: 44, height: 44)
                            .background(icon == option ? color.color : Color("appBackground"))
                            .foregroundStyle(icon == option ? .white : Color("textPrimary"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listRowBackground(Color("cardBackground"))
    }
}
