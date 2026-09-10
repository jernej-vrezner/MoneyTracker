//
//  AddGoalView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//

//
//  AddCategoryView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//


import SwiftUI
import SwiftData

struct AddGoalView: View {
    @State var name: String = ""
    @State var targetAmount: Decimal = 0
    @State var deadline: Date = Date()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section(header: Text("Name")) {
                TextField("Name", text: $name)
            }
            Section(header: Text("Ciljni znesek")) {
                TextField("Ciljni znesek", value: $targetAmount, format: .currency(code: "EUR"))
            }
            Section(header: Text("Rok")) {
                DatePicker("Rok", selection: $deadline, displayedComponents: .date)
            }
            Section {
                Button("Shrani") {
                    let newGoal = Goal(name: name, targetAmount: targetAmount, savedAmount: 0, deadline: deadline)
                    modelContext.insert(newGoal)
                    dismiss()
                }
            }
           
        }
    }
}
