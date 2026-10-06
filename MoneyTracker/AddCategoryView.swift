//
//  AddCategoryView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//

import SwiftUI
import SwiftData

struct AddCategoryView: View {
    @State var name: String = ""
    @State var color: CategoryColor = .red
    @State private var monthlyLimitText: String = ""
    @State var icon: String = "tag.fill"
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let iconOptions = ["fork.knife", "car.fill", "bag.fill", "house.fill", "gamecontroller.fill", "heart.fill", "airplane", "creditcard.fill", "gift.fill", "tag.fill"]

    var body: some View {
        Form {
            Section(header: Text("IME").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                TextField("Ime kategorije", text: $name)
            }
            .listRowBackground(Color("cardBackground"))

            Section(header: Text("BARVA").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                Picker("Barva", selection: $color) {
                    ForEach(CategoryColor.allCases, id: \.self) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
            }
            .listRowBackground(Color("cardBackground"))

            Section(header: Text("IKONA").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                LazyVGrid(columns: Array(repeating: GridItem(), count: 5)) {
                    ForEach(iconOptions, id: \.self) { option in
                        Button {
                            icon = option
                        } label: {
                            Image(systemName: option)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(icon == option ? Color.accentColor : Color("appBackground"))
                                .foregroundStyle(icon == option ? .white : Color("textPrimary"))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listRowBackground(Color("cardBackground"))

            Section(header: Text("MESEČNI LIMIT").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                TextField("0,00 €", text: $monthlyLimitText)
                    .keyboardType(.decimalPad)
            }
            .listRowBackground(Color("cardBackground"))

            Section {
                Button("Shrani") {
                    let limitValue = Decimal(string: monthlyLimitText.replacingOccurrences(of: ",", with: ".")) ?? 0
                    let newCategory = Category(name: name, color: color, monthlyLimit: limitValue, icon: icon)
                    modelContext.insert(newCategory)
                    dismiss()
                }
                .foregroundStyle(Color.accentColor)
                .fontWeight(.semibold)
            }
            .listRowBackground(Color("cardBackground"))
        }
        .scrollContentBackground(.hidden)
        .background(Color("appBackground"))
    }
}
