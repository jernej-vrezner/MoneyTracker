//
//  StatisticsView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 6. 10. 2026.
//

import SwiftUI
import SwiftData
import Charts

struct BarPoint: Identifiable {
    let id = UUID()
    let label: String
    let kind: String
    let amount: Double
}
struct CumulativePoint: Identifiable {
    let id = UUID()
    let day: Int
    let amount: Double
    let series: String
}

struct CategoryTotal: Identifiable {
    var id: String { name }
    let name: String
    let icon: String
    let color: Color
    let amount: Decimal
}
struct TopExpense: Identifiable {
    let id: String
    let name: String
    let subtitle: String?
    let color: Color
    let amount: Decimal
}

struct MonthRow: Identifiable {
    var id: String { label }
    let label: String
    let income: Decimal
    let expense: Decimal
    var net: Decimal { income - expense }
}

struct StatisticsView: View {
    @Query private var transactions: [Transaction]
    @State private var period: StatsPeriod = .month

    private var periodTransactions: [Transaction] {
        let interval = period.current
        return transactions.filter { $0.date >= interval.start && $0.date < interval.end }
    }

    private var income: Decimal {
        periodTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var expense: Decimal {
        periodTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var saved: Decimal { income - expense }

    private var savingsRate: Int {
        guard income > 0 else { return 0 }
        return Int(Double(truncating: (saved / income) as NSNumber) * 100)
    }

    private var averagePerDay: Decimal {
        let days = Calendar.current.dateComponents([.day], from: period.current.start, to: Date()).day ?? 0
        return expense / Decimal(max(days + 1, 1))
    }

    private var largestExpense: Decimal {
        periodTransactions.filter { $0.type == .expense }.map(\.amount).max() ?? 0
    }
    
    private var buckets: [(label: String, interval: DateInterval)] {
        let calendar = Calendar.current
        let interval = period.current
        switch period {
        case .month:
            let days = calendar.range(of: .day, in: .month, for: interval.start)!.count
            return (0..<((days + 6) / 7)).map { i in
                let start = calendar.date(byAdding: .day, value: i * 7, to: interval.start)!
                let end = min(calendar.date(byAdding: .day, value: (i + 1) * 7, to: interval.start)!, interval.end)
                return ("T\(i + 1)", DateInterval(start: start, end: end))
            }
        case .quarter, .year:
            let count = period == .quarter ? 3 : 12
            return (0..<count).map { i in
                let start = calendar.date(byAdding: .month, value: i, to: interval.start)!
                let end = calendar.date(byAdding: .month, value: 1, to: start)!
                return (start.formatted(.dateTime.month(.abbreviated)), DateInterval(start: start, end: end))
            }
        }
    }

    private var barPoints: [BarPoint] {
        buckets.flatMap { bucket -> [BarPoint] in
            let items = periodTransactions.filter { $0.date >= bucket.interval.start && $0.date < bucket.interval.end }
            let inc = items.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let exp = items.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return [
                BarPoint(label: bucket.label, kind: "Prilivi", amount: Double(truncating: inc as NSNumber)),
                BarPoint(label: bucket.label, kind: "Odlivi", amount: Double(truncating: exp as NSNumber))
            ]
        }
    }
    
    private func cumulativeSeries(for interval: DateInterval, name: String, until limit: Date) -> [CumulativePoint] {
        let calendar = Calendar.current
        let expenses = transactions.filter {
            $0.type == .expense && $0.date >= interval.start && $0.date < interval.end
        }
        let byDay = Dictionary(grouping: expenses) {
            calendar.dateComponents([.day], from: interval.start, to: $0.date).day ?? 0
        }
        let totalDays = calendar.dateComponents([.day], from: interval.start, to: interval.end).day ?? 0

        var running = 0.0
        var points: [CumulativePoint] = []
        for day in 0..<totalDays {
            let dayStart = calendar.date(byAdding: .day, value: day, to: interval.start)!
            if dayStart > limit { break }
            let daySum = byDay[day]?.reduce(Decimal(0)) { $0 + $1.amount } ?? 0
            running += Double(truncating: daySum as NSNumber)
            points.append(CumulativePoint(day: day + 1, amount: running, series: name))
        }
        return points
    }
    
    private var cumulativePoints: [CumulativePoint] {
        cumulativeSeries(for: period.current, name: "Izbrano obdobje", until: Date())
        + cumulativeSeries(for: period.previous, name: "Prejšnje", until: .distantFuture)
    }
    
    private var categoryTotals: [CategoryTotal] {
        let expenses = periodTransactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses) { $0.category?.persistentModelID }
        return grouped.values.map { items -> CategoryTotal in
            let category = items.first?.category
            return CategoryTotal(
                name: category?.name ?? "Brez kategorije",
                icon: category?.icon ?? "questionmark.circle",
                color: category?.color.color ?? Color("textSecondary"),
                amount: items.reduce(Decimal(0)) { $0 + $1.amount }
            )
        }
        .sorted { $0.amount > $1.amount }
    }

    private func percent(_ amount: Decimal) -> Int {
        guard expense > 0 else { return 0 }
        return Int(Double(truncating: (amount / expense) as NSNumber) * 100)
    }

    private func ratioToLargest(_ amount: Decimal) -> Double {
        guard let largest = categoryTotals.first?.amount, largest > 0 else { return 0 }
        return Double(truncating: (amount / largest) as NSNumber)
    }
    private var topExpenses: [TopExpense] {
        let expenses = periodTransactions.filter { $0.type == .expense }
        let grouped = Dictionary(grouping: expenses) { transaction -> String in
            let categoryName = transaction.category?.name ?? "Brez kategorije"
            if let sub = transaction.subcategory {
                return "sub|\(categoryName)|\(sub.name)"
            }
            return "cat|\(categoryName)"
        }
        let totals = grouped.map { key, items -> TopExpense in
            let first = items[0]
            let amount = items.reduce(Decimal(0)) { $0 + $1.amount }
            let color = first.category?.color.color ?? Color("textSecondary")
            if let sub = first.subcategory {
                return TopExpense(id: key, name: sub.name, subtitle: first.category?.name, color: color, amount: amount)
            }
            return TopExpense(id: key, name: first.category?.name ?? "Brez kategorije", subtitle: nil, color: color, amount: amount)
        }
        .sorted { $0.amount > $1.amount }
        return Array(totals.prefix(5))
    }

    private var monthRows: [MonthRow] {
        let calendar = Calendar.current
        let thisMonthStart = calendar.dateInterval(of: .month, for: Date())!.start
        return (0..<12).map { i -> MonthRow in
            let start = calendar.date(byAdding: .month, value: -i, to: thisMonthStart)!
            let end = calendar.date(byAdding: .month, value: 1, to: start)!
            let items = transactions.filter { $0.date >= start && $0.date < end }
            return MonthRow(
                label: start.formatted(.dateTime.month(.abbreviated).year(.twoDigits)),
                income: items.filter { $0.type == .income }.reduce(Decimal(0)) { $0 + $1.amount },
                expense: items.filter { $0.type == .expense }.reduce(Decimal(0)) { $0 + $1.amount }
            )
        }
    }

    private func ratio(_ amount: Decimal, to maximum: Decimal) -> Double {
        guard maximum > 0 else { return 0 }
        return Double(truncating: (amount / maximum) as NSNumber)
    }
    private func euro(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR"))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Statistika")

            ScrollView {
                VStack(spacing: 12) {
                    Picker("Obdobje", selection: $period) {
                        ForEach(StatsPeriod.allCases) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 12) {
                        StatTile(label: "PRILIVI", value: "+" + euro(income), color: Color("positiveColor"))
                        StatTile(label: "ODLIVI", value: "-" + euro(expense), color: Color("negativeColor"))
                    }
                    HStack(spacing: 12) {
                        StatTile(label: "PRIHRANJENO", value: euro(saved))
                        StatTile(label: "STOPNJA VARČEVANJA", value: "\(savingsRate) %", color: Color.accentColor)
                    }
                    HStack(spacing: 12) {
                        StatTile(label: "POVPREČJE NA DAN", value: euro(averagePerDay))
                        StatTile(label: "NAJVEČJI ODLIV", value: euro(largestExpense))
                        StatTile(label: "ŠT. TRANSAKCIJ", value: "\(periodTransactions.count)")
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRILIVI IN ODLIVI")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Color("textSecondary"))
                        Chart(barPoints) { point in
                            BarMark(
                                x: .value("Obdobje", point.label),
                                y: .value("€", point.amount)
                            )
                            .foregroundStyle(by: .value("Tip", point.kind))
                            .position(by: .value("Tip", point.kind))
                        }
                        .chartForegroundStyleScale([
                            "Prilivi": Color("positiveColor"),
                            "Odlivi": Color("negativeColor")
                        ])
                        .frame(height: 170)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("KUMULATIVNA PORABA")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Color("textSecondary"))
                        Text("polna črta: izbrano obdobje · črtkano: prejšnje")
                            .font(.caption)
                            .foregroundStyle(Color("textSecondary"))
                        Chart(cumulativePoints) { point in
                            if point.series == "Izbrano obdobje" {
                                AreaMark(
                                    x: .value("Dan", point.day),
                                    y: .value("€", point.amount)
                                )
                                .foregroundStyle(Color.accentColor.opacity(0.12))
                            }
                            LineMark(
                                x: .value("Dan", point.day),
                                y: .value("€", point.amount),
                                series: .value("Obdobje", point.series)
                            )
                            .foregroundStyle(by: .value("Obdobje", point.series))
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: point.series == "Prejšnje" ? [4, 3] : []))
                        }
                        .chartForegroundStyleScale([
                            "Izbrano obdobje": Color.accentColor,
                            "Prejšnje": Color("textSecondary")
                        ])
                        .chartLegend(.hidden)
                        .frame(height: 150)
                    }
                    VStack(alignment: .leading, spacing: 14) {
                        Text("PO KATEGORIJAH")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Color("textSecondary"))

                        if categoryTotals.isEmpty {
                            Text("Ni odlivov v tem obdobju")
                                .font(.caption)
                                .foregroundStyle(Color("textSecondary"))
                        } else {
                            HStack(alignment: .center, spacing: 16) {
                                Chart(categoryTotals) { item in
                                    SectorMark(
                                        angle: .value("€", Double(truncating: item.amount as NSNumber)),
                                        innerRadius: .ratio(0.62),
                                        angularInset: 1.5
                                    )
                                    .foregroundStyle(item.color)
                                    .cornerRadius(3)
                                }
                                .frame(width: 120, height: 120)

                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(categoryTotals.prefix(6)) { item in
                                        HStack(spacing: 6) {
                                            Circle().fill(item.color).frame(width: 8, height: 8)
                                            Text(item.name)
                                                .font(.caption)
                                                .foregroundStyle(Color("textPrimary"))
                                                .lineLimit(1)
                                            Spacer()
                                            Text("\(percent(item.amount)) %")
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundStyle(Color("textSecondary"))
                                        }
                                    }
                                }
                            }

                            ForEach(categoryTotals) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        CategoryIconBadge(icon: item.icon, color: item.color)
                                        Text(item.name)
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(Color("textPrimary"))
                                        Spacer()
                                        Text(euro(item.amount))
                                            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                            .foregroundStyle(Color("textPrimary"))
                                    }
                                    CategoryProgressBar(progress: ratioToLargest(item.amount), color: item.color)
                                }
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("NAJVEČJI IZDATKI")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Color("textSecondary"))

                        if topExpenses.isEmpty {
                            Text("Ni odlivov v tem obdobju")
                                .font(.caption)
                                .foregroundStyle(Color("textSecondary"))
                        } else {
                            ForEach(topExpenses) { item in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(item.name)
                                            .font(.subheadline)
                                            .foregroundStyle(Color("textPrimary"))
                                        if let subtitle = item.subtitle {
                                            Text(subtitle)
                                                .font(.caption)
                                                .foregroundStyle(Color("textSecondary"))
                                        }
                                        Spacer()
                                        Text(euro(item.amount))
                                            .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                            .foregroundStyle(Color("textPrimary"))
                                    }
                                    CategoryProgressBar(
                                        progress: ratio(item.amount, to: topExpenses.first?.amount ?? 0),
                                        color: item.color
                                    )
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 14) {
                        Text("PO MESECIH")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Color("textSecondary"))
                        Text("črta: delež prilivov, ki si ga porabil")
                            .font(.caption)
                            .foregroundStyle(Color("textSecondary"))

                        ForEach(monthRows) { row in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(row.label)
                                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                        .foregroundStyle(Color("textPrimary"))
                                    Spacer()
                                    Text((row.net >= 0 ? "+" : "") + euro(row.net))
                                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                        .foregroundStyle(row.net >= 0 ? Color("positiveColor") : Color("negativeColor"))
                                }
                                Text("Prilivi \(euro(row.income)) · Odlivi \(euro(row.expense))")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(Color("textSecondary"))
                                CategoryProgressBar(
                                    progress: row.income > 0 ? ratio(row.expense, to: row.income) : (row.expense > 0 ? 1 : 0),
                                    color: Color("negativeColor")
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .cardStyle()
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Color("appBackground"))
    }
}
