//
//  AccountPillPicker.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 13. 10. 2026.
//

import SwiftUI
import SwiftData

struct AccountPillPicker: View {
    let accounts: [Account]
    @Binding var selectedAccount: Account?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(accounts) { account in
                    Button {
                        selectedAccount = (selectedAccount == account) ? nil : account
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: account.kind.iconName)
                            Text(account.name)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedAccount == account ? account.color.color : Color("cardBackground"))
                        .foregroundStyle(selectedAccount == account ? .white : Color("textPrimary"))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}
