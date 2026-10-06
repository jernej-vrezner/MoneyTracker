//
//  EditCategoryView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 6. 10. 2026.
//

import SwiftUI
import SwiftData

struct EditCategoryView: View {
    @Bindable var category: Category
    @State private var newSubcategoryName = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private var sortedSubcategories: [Subcategory] {
        (category.subcategories ?? []).sorted { $0.name < $1.name }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("IME").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    TextField("Ime kategorije", text: $category.name)
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: Text("PODKATEGORIJE").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    ForEach(sortedSubcategories) { sub in
                        SubcategoryEditRow(subcategory: sub)
                    }
                    .onDelete(perform: deleteSubcategories)

                    HStack {
                        TextField("Nova podkategorija", text: $newSubcategoryName)
                        Button("Dodaj") {
                            addSubcategory()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .listRowBackground(Color("cardBackground"))
            }
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
            .navigationTitle("Uredi kategorijo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Končaj") { dismiss() }
                }
            }
        }
    }

    
    struct SubcategoryEditRow: View {
        @Bindable var subcategory: Subcategory

        var body: some View {
            HStack {
                Text(subcategory.name)
                Spacer()
                TextField("Brez limita", value: $subcategory.monthlyLimit, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 110)
            }
        }
    }
    
    private func addSubcategory() {
        let name = newSubcategoryName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        modelContext.insert(Subcategory(name: name, parent: category))
        newSubcategoryName = ""
    }

    private func deleteSubcategories(offsets: IndexSet) {
        let subs = sortedSubcategories
        for index in offsets {
            modelContext.delete(subs[index])
        }
    }
}
