import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var transactions: [Transaction]
    @Query private var subscriptions: [Subscription]
    @State private var displayedMonth: Date = Date()
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var transactionToEdit: Transaction? = nil

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        return calendar
    }

    private var monthStart: Date {
        calendar.dateInterval(of: .month, for: displayedMonth)?.start ?? displayedMonth
    }

    private var daysInMonth: [Date] {
        let count = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: monthStart) }
    }

    private var leadingBlanks: Int {
        let weekday = calendar.component(.weekday, from: monthStart)
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    private var weekdayLabels: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    private var monthTransactions: [Transaction] {
        transactions.filter { calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
    }

    private var transactionsByDay: [Date: [Transaction]] {
        Dictionary(grouping: monthTransactions) { calendar.startOfDay(for: $0.date) }
    }

    private var monthIncome: Decimal {
        monthTransactions.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var monthExpense: Decimal {
        monthTransactions.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var selectedDay: Date {
        calendar.startOfDay(for: selectedDate)
    }

    private var selectedTransactions: [Transaction] {
        (transactionsByDay[selectedDay] ?? []).sorted { $0.date > $1.date }
    }

    private var selectedDayNet: Decimal {
        selectedTransactions.reduce(Decimal(0)) { sum, transaction in
            transaction.type == .income ? sum + transaction.amount : sum - transaction.amount
        }
    }

    private var upcomingSubscriptions: [Subscription] {
        guard calendar.isDate(monthStart, equalTo: Date(), toGranularity: .month) else { return [] }
        let today = calendar.component(.day, from: Date())
        let daysCount = daysInMonth.count
        return subscriptions.filter { subscription in
            let alreadyCharged = calendar.isDate(subscription.lastChargedMonth, equalTo: Date(), toGranularity: .month)
            return !alreadyCharged && min(subscription.billingDay, daysCount) > today
        }
    }

    private func euro(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR"))
    }

    private func changeMonth(by value: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: value, to: monthStart) else { return }
        displayedMonth = newMonth
        if calendar.isDate(newMonth, equalTo: Date(), toGranularity: .month) {
            selectedDate = calendar.startOfDay(for: Date())
        } else {
            selectedDate = calendar.startOfDay(for: newMonth)
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                monthHeader
                statsRow
                calendarCard
                selectedDaySection
                upcomingBox
            }
            .padding(.horizontal)
            .padding(.bottom, 90)
        }
        .background(Color("appBackground"))
        .sheet(item: $transactionToEdit) { transaction in
            AddTransactionView(transaction: transaction)
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                changeMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Color("textPrimary"))
                    .frame(width: 40, height: 40)
                    .background(Color("cardBackground"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()
            Text(monthStart.formatted(.dateTime.month(.wide).year()))
                .font(.headline)
                .foregroundStyle(Color("textPrimary"))
            Spacer()

            Button {
                changeMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color("textPrimary"))
                    .frame(width: 40, height: 40)
                    .background(Color("cardBackground"))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            StatTile(label: "PRILIVI", value: "+" + euro(monthIncome), color: Color("positiveColor"))
            StatTile(label: "ODLIVI", value: "-" + euro(monthExpense), color: Color("negativeColor"))
            StatTile(label: "NETO", value: euro(monthIncome - monthExpense))
        }
    }

    private var calendarCard: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { _, label in
                    Text(label)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color("textSecondary"))
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear.frame(height: 50)
                }
                ForEach(daysInMonth, id: \.self) { day in
                    dayCell(day)
                }
            }
        }
        .cardStyle()
    }

    @ViewBuilder
    private func dayCell(_ day: Date) -> some View {
        let key = calendar.startOfDay(for: day)
        let items = transactionsByDay[key] ?? []
        let hasIncome = items.contains { $0.type == .income }
        let hasExpense = items.contains { $0.type != .income }
        let isSelected = key == selectedDay
        let isToday = calendar.isDateInToday(day)
        let isFuture = key > calendar.startOfDay(for: Date())

        Button {
            selectedDate = key
        } label: {
            VStack(spacing: 4) {
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(.subheadline, design: .monospaced).weight(isSelected || isToday ? .bold : .regular))
                HStack(spacing: 3) {
                    if hasIncome {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.9) : Color("positiveColor"))
                            .frame(width: 5, height: 5)
                    }
                    if hasExpense {
                        Circle()
                            .fill(isSelected ? Color.white.opacity(0.9) : Color("negativeColor"))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(isSelected ? Color.white : (isFuture ? Color("textSecondary") : Color("textPrimary")))
            .background(
                isSelected ? Color.accentColor
                : (isToday ? Color.accentColor.opacity(0.18)
                   : (items.isEmpty ? Color.clear : Color("appBackground")))
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(selectedDate.formatted(.dateTime.day().month(.wide).year()).uppercased())
                Spacer()
                Text((selectedDayNet >= 0 ? "+" : "") + euro(selectedDayNet))
            }
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Color("textSecondary"))

            VStack(spacing: 0) {
                if selectedTransactions.isEmpty {
                    Text("Ni transakcij ta dan.")
                        .font(.caption)
                        .foregroundStyle(Color("textSecondary"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 6)
                } else {
                    ForEach(selectedTransactions) { transaction in
                        transactionRow(transaction)
                        if transaction.id != selectedTransactions.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
    }

    private func transactionRow(_ transaction: Transaction) -> some View {
        HStack(spacing: 12) {
            CategoryIconBadge(
                icon: transaction.category?.icon ?? "questionmark.circle",
                color: transaction.category?.color.color ?? Color("textSecondary")
            )
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? (transaction.category?.name ?? "Brez kategorije") : transaction.note)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("textPrimary"))
                    .lineLimit(1)
                Text((transaction.category?.name ?? "Brez kategorije")
                     + (transaction.subcategory.map { " › " + $0.name } ?? "")
                     + " · " + transaction.date.formatted(.dateTime.day().month(.abbreviated)))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color("textSecondary"))
                    .lineLimit(1)
            }
            Spacer()
            Text((transaction.type == .income ? "+" : "-") + euro(transaction.amount))
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(transaction.type == .income ? Color("positiveColor") : Color("negativeColor"))
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { transactionToEdit = transaction }
    }

    @ViewBuilder
    private var upcomingBox: some View {
        if !upcomingSubscriptions.isEmpty {
            let total = upcomingSubscriptions.reduce(Decimal(0)) { $0 + $1.amount }
            Text("Do konca meseca še načrtovani odlivi: \(upcomingSubscriptions.count) (−\(euro(total)))")
                .font(.caption)
                .foregroundStyle(Color("positiveColor"))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("positiveColor").opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}
