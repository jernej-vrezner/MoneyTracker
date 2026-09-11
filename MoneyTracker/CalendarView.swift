//
//  CalendarView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 11. 9. 2026.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var transactions: [Transaction]
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date? = nil
    
    var daysInMonth: [Date] {
        let calendar = Calendar.current
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        return range.compactMap { day in
            calendar.date(from: DateComponents(year: components.year, month: components.month, day: day))
        }
    }
    var transactionsForSelectedDate: [Transaction] {
        guard let selectedDate else { return [] }
        return transactions.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    private func hasTransactions(on day: Date) -> Bool {
        transactions.contains { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }
    var body: some View {
        VStack{
            HStack {
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                Spacer()
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth)!
                } label: {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(daysInMonth, id: \.self) { day in
                    Button {
                        selectedDate = day
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: day))")
                            Circle()
                                .fill(hasTransactions(on: day) ? Color.blue : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            List(transactionsForSelectedDate) { transaction in
                Text("\(transaction.category?.name ?? "Brez kategorije") – \(transaction.amount.formatted(.currency(code: "EUR")))")
            }
        }
    }
}
