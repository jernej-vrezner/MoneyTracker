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
    @State var monthlyLimit: Decimal = 0
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Name", text: $name)
            }
            Section(header: Text("Color")) {
                Picker("Color", selection: $color) {
                    ForEach(CategoryColor.allCases, id: \.self) { c in
                        Text(c.rawValue).tag(c)
                    }
                }
            }
            Section(header: Text("Monthly limit")) {
                TextField("Monthly limit", value: $monthlyLimit, format: .currency(code: "EUR"))
            }
            Section {
                Button("Shrani") {
                    // TODO: ustvari Category(name:color:monthlyLimit:), modelContext.insert(...), dismiss()
                    let newCategory = Category(name: name, color: color, monthlyLimit: monthlyLimit)
                    modelContext.insert(newCategory)
                    dismiss()
                }
            }
        }
    }
}
