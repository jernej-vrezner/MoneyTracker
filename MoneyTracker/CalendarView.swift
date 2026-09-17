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
    var transactionsInDisplayedMonth: [Transaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: displayedMonth, toGranularity: .month) }
    }

    var monthIncome: Decimal {
        transactionsInDisplayedMonth.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var monthExpense: Decimal {
        transactionsInDisplayedMonth.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var monthNet: Decimal {
        monthIncome - monthExpense
    }
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth)!
                } label: {
                    Image(systemName: "chevron.left")
                }
                .foregroundStyle(Color("textPrimary"))
                Spacer()
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .foregroundStyle(Color("textPrimary"))
                Spacer()
                Button {
                    displayedMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth)!
                } label: {
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(Color("textPrimary"))
            }
            .padding(.horizontal)
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PRILIVI")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color("textSecondary"))
                    Text(monthIncome.formatted(.currency(code: "EUR")))
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Color("positiveColor"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                VStack(alignment: .leading, spacing: 2) {
                    Text("ODLIVI")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color("textSecondary"))
                    Text(monthExpense.formatted(.currency(code: "EUR")))
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Color("negativeColor"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()

                VStack(alignment: .leading, spacing: 2) {
                    Text("NETO")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color("textSecondary"))
                    Text(monthNet.formatted(.currency(code: "EUR")))
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(Color("textPrimary"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .cardStyle()
            }
            .padding(.horizontal)
            LazyVGrid(columns: Array(repeating: GridItem(), count: 7)) {
                ForEach(daysInMonth, id: \.self) { day in
                    Button {
                        selectedDate = day
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(Calendar.current.component(.day, from: day))")
                                .foregroundStyle(Color("textPrimary"))
                            Circle()
                                .fill(hasTransactions(on: day) ? Color.accentColor : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .cardStyle()

            List(transactionsForSelectedDate) { transaction in
                HStack {
                    CategoryIconBadge(
                        icon: transaction.category?.icon ?? "questionmark.circle",
                        color: transaction.category?.color.color ?? Color("textSecondary")
                    )
                    Text(transaction.category?.name ?? "Brez kategorije")
                        .foregroundStyle(Color("textPrimary"))
                    Spacer()
                    Text(transaction.amount.formatted(.currency(code: "EUR")))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(transaction.type == .income ? Color("positiveColor") : Color("negativeColor"))
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color("cardBackground"))
                        .padding(.vertical, 4)
                )
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .padding(.top)
        .background(Color("appBackground"))
    }
}
