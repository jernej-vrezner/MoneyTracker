//
//  AddTransactionView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 9. 9. 2026.
//
import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @State var date: Date = Date()
    @State var type: TransactioType = .expense
    @State var note: String = ""
    @State var selectedCategory: Category? = nil
    @State private var selectedSubcategory: Subcategory? = nil
    @State private var amountInput: String = "0"
    @State private var showingDatePicker = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [Category]

    let transactionToEdit: Transaction?

    init(transaction: Transaction? = nil) {
        self.transactionToEdit = transaction
        if let transaction {
            _date = State(initialValue: transaction.date)
            _type = State(initialValue: transaction.type)
            _note = State(initialValue: transaction.note)
            _selectedCategory = State(initialValue: transaction.category)
            _selectedSubcategory = State(initialValue: transaction.subcategory)
            _amountInput = State(initialValue: "\(transaction.amount)")
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                Picker("Tip", selection: $type) {
                    Text("Odliv").tag(TransactioType.expense)
                    Text("Priliv").tag(TransactioType.income)
                }
                .pickerStyle(.segmented)
                .padding()

                VStack(spacing: 4) {
                    Text((type == .expense ? "-" : "") + amountInput.replacingOccurrences(of: ".", with: ",") + " €")
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .foregroundStyle(type == .expense ? Color("negativeColor") : Color("positiveColor"))
                    Button {
                        showingDatePicker = true
                    } label: {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline)
                            .foregroundStyle(Color("textSecondary"))
                    }
                    .popover(isPresented: $showingDatePicker) {
                        DatePicker("Datum", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding()
                            .frame(minWidth: 320, minHeight: 360)
                    }
                }
                .padding(.top, 24)
                CategoryPillPicker(
                    categories: categories,
                    selectedCategory: $selectedCategory,
                    selectedSubcategory: $selectedSubcategory
                )
                .padding(.top, 20)
                TextField("Dodaj opombo (neobvezno)", text: $note)
                    .padding(12)
                    .background(Color("cardBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal)
                    .padding(.top, 16)

                Spacer()

                NumericKeypad(input: $amountInput)

                Spacer()
            }
            .navigationTitle(transactionToEdit == nil ? "Nova transakcija" : "Uredi transakcijo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Prekliči") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Shrani") {
                        let amount = Decimal(string: amountInput) ?? 0
                        if let transaction = transactionToEdit {
                            transaction.amount = amount
                            transaction.date = date
                            transaction.type = type
                            transaction.note = note
                            transaction.category = selectedCategory
                            transaction.subcategory = selectedSubcategory
                        } else {
                            let newTransaction = Transaction(amount: amount, date: date, type: type, note: note, category: selectedCategory)
                            modelContext.insert(newTransaction)
                            newTransaction.subcategory = selectedSubcategory
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}
