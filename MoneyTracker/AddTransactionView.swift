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
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories) { category in
                            Button {
                                selectedCategory = category
                                selectedSubcategory = nil
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: category.icon)
                                    Text(category.name)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedCategory == category ? category.color.color : Color("cardBackground"))
                                .foregroundStyle(selectedCategory == category ? .white : Color("textPrimary"))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 20)
                if let selectedCategory, let subs = selectedCategory.subcategories, !subs.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            Button {
                                selectedSubcategory = nil
                            } label: {
                                Text("Brez")
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(selectedSubcategory == nil ? selectedCategory.color.color : Color("cardBackground"))
                                    .foregroundStyle(selectedSubcategory == nil ? .white : Color("textPrimary"))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            ForEach(subs.sorted { $0.name < $1.name }) { sub in
                                Button {
                                    selectedSubcategory = sub
                                } label: {
                                    Text(sub.name)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(selectedSubcategory == sub ? selectedCategory.color.color : Color("cardBackground"))
                                        .foregroundStyle(selectedSubcategory == sub ? .white : Color("textPrimary"))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
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
            .navigationTitle("Nova transakcija")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Prekliči") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Shrani") {
                        let newTransaction = Transaction(amount: Decimal(string: amountInput) ?? 0, date: date, type: type, note: note, category: selectedCategory)
                        modelContext.insert(newTransaction)
                        newTransaction.subcategory = selectedSubcategory
                        dismiss()
                    }
                }
            }
        }
    }
}
