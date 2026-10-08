//
//  ScreenHeader.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 6. 10. 2026.
//

import SwiftUI

struct ScreenHeader: View {
    let title: String
    @State private var showingSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Date().formatted(.dateTime.month(.wide).year()))
                .font(.system(.caption, design: .monospaced))
                .textCase(.uppercase)
                .foregroundStyle(Color("textSecondary"))
            HStack {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("textPrimary"))
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(Color("textPrimary"))
                            .frame(width: 32, height: 32)
                            .background(Color("cardBackground"))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    Text("Uredi")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding()
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}
