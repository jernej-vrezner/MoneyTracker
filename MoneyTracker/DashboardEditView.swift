//
//  DashboardEditView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 12. 10. 2026.
//

import SwiftUI

struct DashboardEditView: View {
    @AppStorage("dashboardOrder") private var orderRaw = ""
    @AppStorage("dashboardHidden") private var hiddenRaw = ""
    @Environment(\.dismiss) private var dismiss

    private var cards: [DashboardCard] { DashboardCard.decode(orderRaw) }
    private var hidden: Set<DashboardCard> { DashboardCard.decodeSet(hiddenRaw) }

    var body: some View {
        NavigationStack {
            List {
                ForEach(cards) { card in
                    Toggle(card.title, isOn: Binding(
                        get: { !hidden.contains(card) },
                        set: { isVisible in
                            var updated = hidden
                            if isVisible {
                                updated.remove(card)
                            } else {
                                updated.insert(card)
                            }
                            hiddenRaw = DashboardCard.encode(Array(updated))
                        }
                    ))
                }
                .onMove { source, destination in
                    var updated = cards
                    updated.move(fromOffsets: source, toOffset: destination)
                    orderRaw = DashboardCard.encode(updated)
                }
            }
            .environment(\.editMode, .constant(.active))
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
            .navigationTitle("Uredi pregled")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Končaj") { dismiss() }
                }
            }
        }
    }
}
