//
//  AddTransactionView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 9. 9. 2026.
//
import SwiftUI
import SwiftData

struct AddTransactionView: View {
    
    
    @State var amount:Decimal = 0
    @State var date:Date = Date()
    @State var type:TransactioType = .expense
    @State var note:String = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("Amount")) {
                TextField("Amount", value: $amount, format: .currency(code: "EUR"))
            }
            Section(header: Text("Date")) {
                DatePicker("Date", selection: $date)
            }
            Section(header: Text("Type")) {
                Picker("Type", selection: $type) {
                    ForEach(TransactioType.allCases, id: \.self) { t in Text(t.rawValue).tag(t) }
                }
            }
            Section(header: Text("Note")) {
                TextEditor(text: $note)
            }
            Section {
                Button("Shrani") {
                    let newTransaction = Transaction(amount: amount, date: date, type: type, note: note)
                    modelContext.insert(newTransaction)
                    dismiss()
                }
            }
        }
    }
}
