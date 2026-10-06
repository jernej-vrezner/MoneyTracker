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
    @State private var subcategoryNames: [String] = []
    @State private var newSubcategoryName = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text("IME").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                TextField("Ime kategorije", text: $name)
            }
            .listRowBackground(Color("cardBackground"))

            CategoryAppearancePicker(color: $color, icon: $icon)

            Section(header: Text("MESEČNI LIMIT").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                TextField("0,00 €", text: $monthlyLimitText)
                    .keyboardType(.decimalPad)
            }
            .listRowBackground(Color("cardBackground"))

            Section(header: Text("PODKATEGORIJE").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                ForEach(subcategoryNames, id: \.self) { subName in
                    Text(subName)
                }
                .onDelete { offsets in
                    subcategoryNames.remove(atOffsets: offsets)
                }

                HStack {
                    TextField("Nova podkategorija", text: $newSubcategoryName)
                    Button("Dodaj") {
                        addSubcategoryName()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                }
            }
            .listRowBackground(Color("cardBackground"))

            Section {
                Button("Shrani") {
                    let limitValue = Decimal(string: monthlyLimitText.replacingOccurrences(of: ",", with: ".")) ?? 0
                    let newCategory = Category(name: name, color: color, monthlyLimit: limitValue, icon: icon)
                    modelContext.insert(newCategory)
                    for subName in subcategoryNames {
                        modelContext.insert(Subcategory(name: subName, parent: newCategory))
                    }
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

    private func addSubcategoryName() {
        let trimmed = newSubcategoryName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !subcategoryNames.contains(trimmed) else { return }
        subcategoryNames.append(trimmed)
        newSubcategoryName = ""
    }
}
