//
//  AddGoalView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//

import SwiftUI
import SwiftData

struct AddGoalView: View {
    @State private var name: String = ""
    @State private var targetText: String = ""
    @State private var savedText: String = ""
    @State private var deadline: Date = Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
    @State private var showingDatePicker = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let goalToEdit: Goal?

    init(goal: Goal? = nil) {
        self.goalToEdit = goal
        if let goal {
            _name = State(initialValue: goal.name)
            _targetText = State(initialValue: "\(goal.targetAmount)".replacingOccurrences(of: ".", with: ","))
            _savedText = State(initialValue: "\(goal.savedAmount)".replacingOccurrences(of: ".", with: ","))
            _deadline = State(initialValue: goal.deadline)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func parse(_ text: String) -> Decimal {
        Decimal(string: text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("IME CILJA").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    TextField("Npr. Nov računalnik", text: $name)
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: Text("CILJNI ZNESEK").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    TextField("0,00 €", text: $targetText)
                        .keyboardType(.decimalPad)
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: Text("ROK").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    Button {
                        showingDatePicker = true
                    } label: {
                        HStack {
                            Text(deadline.formatted(.dateTime.day().month(.wide).year()))
                                .foregroundStyle(Color("textPrimary"))
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingDatePicker) {
                        DatePicker("Rok", selection: $deadline, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding()
                            .frame(minWidth: 320, minHeight: 360)
                    }
                }
                .listRowBackground(Color("cardBackground"))

                if goalToEdit != nil {
                    Section(
                        header: Text("PRIHRANJENO").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary")),
                        footer: Text("Popraviš lahko znesek, če si pri prispevku naredil napako.")
                    ) {
                        TextField("0,00 €", text: $savedText)
                            .keyboardType(.decimalPad)
                    }
                    .listRowBackground(Color("cardBackground"))
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
            .navigationTitle(goalToEdit == nil ? "Nov cilj" : "Uredi cilj")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Prekliči") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Shrani") {
                        save()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let goal = goalToEdit {
            goal.name = trimmedName
            goal.targetAmount = parse(targetText)
            goal.savedAmount = parse(savedText)
            goal.deadline = deadline
        } else {
            let newGoal = Goal(name: trimmedName, targetAmount: parse(targetText), savedAmount: 0, deadline: deadline)
            modelContext.insert(newGoal)
        }
        dismiss()
    }
}
