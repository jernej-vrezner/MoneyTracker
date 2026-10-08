//
//  CategoryPillPicker.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 8. 10. 2026.
//

import SwiftUI

struct CategoryPillPicker: View {
    let categories: [Category]
    @Binding var selectedCategory: Category?
    @Binding var selectedSubcategory: Subcategory?

    var body: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(categories) { category in
                        Button {
                            selectedCategory = (selectedCategory == category) ? nil : category
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
            }
        }
    }
}
