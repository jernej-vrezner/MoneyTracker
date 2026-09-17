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
    @State var icon: String = "tag.fill"
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let iconOptions = ["fork.knife", "car.fill", "bag.fill", "house.fill", "gamecontroller.fill", "heart.fill", "airplane", "creditcard.fill", "gift.fill", "tag.fill"]
    
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
            Section(header: Text("Ikona")) {
                LazyVGrid(columns: Array(repeating: GridItem(), count: 5)) {
                    ForEach(iconOptions, id: \.self) { option in
                        Button {
                            icon = option
                        } label: {
                            Image(systemName: option)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .background(icon == option ? Color.accentColor : Color("cardBackground"))
                                .foregroundStyle(icon == option ? .white : Color("textPrimary"))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Section(header: Text("Monthly limit")) {
                TextField("Monthly limit", value: $monthlyLimit, format: .currency(code: "EUR"))
            }
            Section {
                Button("Shrani") {
                    // TODO: ustvari Category(name:color:monthlyLimit:), modelContext.insert(...), dismiss()
                    let newCategory = Category(name: name, color: color, monthlyLimit: monthlyLimit,icon: icon)
                    modelContext.insert(newCategory)
                    dismiss()
                }
            }
        }
    }
}
