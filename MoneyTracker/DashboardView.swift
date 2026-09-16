//
//  DashboardView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//

import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @Query private var subscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext
    
    var transactionsThisMonth: [Transaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }
    
    var totalIncome: Decimal {
        transactionsThisMonth.filter{$0.type == .income}.reduce(0) {$0 + $1.amount}
    }
    
    var totalExpense: Decimal {
        transactionsThisMonth.filter{$0.type == .expense}.reduce(0) {$0 + $1.amount}
    }
    var lastSixMonths: [MonthlyTotal] {
        (0..<6).reversed().map { offset in
            let monthDate = Calendar.current.date(byAdding: .month, value: -offset, to: Date())!
            let monthTransactions = transactions.filter {
                Calendar.current.isDate($0.date, equalTo: monthDate, toGranularity: .month)
            }
            let income = monthTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
            let expense = monthTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
            return MonthlyTotal(month: monthDate, income: income, expense: expense)
        }
    }
    var totalInvestment: Decimal {
        transactionsThisMonth.filter{$0.type == .investment}.reduce(0) {$0 + $1.amount}
    }
    
    var net: Decimal {
        totalIncome - totalExpense
    }
    
    var projectedExpense: Decimal {
        let calendar = Calendar.current
        let daysElapsed = calendar.component(.day, from: Date())
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())!.count
        guard daysElapsed > 0 else { return 0 }
        return totalExpense / Decimal(daysElapsed) * Decimal(daysInMonth)
    }
    
    var recentTransactions: [Transaction] {
        Array(transactions.sorted {$0.date > $1.date}.prefix(5))
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prilivi: \(totalIncome.formatted(.currency(code: "EUR")))")
                    Text("Odlivi: \(totalExpense.formatted(.currency(code: "EUR")))")
                    Text("Investicije: \(totalInvestment.formatted(.currency(code: "EUR")))")
                    Text("Neto: \(net.formatted(.currency(code: "EUR")))")
                }
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color("textPrimary"))
                .cardStyle()

                Chart(categories) { category in
                    BarMark(
                        x: .value("Kategorija", category.name),
                        y: .value("Znesek", Double(truncating: spent(for: category) as NSNumber))
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .frame(height: 200)
                .cardStyle()

                Chart(lastSixMonths) { item in
                    BarMark(
                        x: .value("Mesec", item.month, unit: .month),
                        y: .value("Znesek", Double(truncating: item.income as NSNumber))
                    )
                    .foregroundStyle(Color("positiveColor"))

                    BarMark(
                        x: .value("Mesec", item.month, unit: .month),
                        y: .value("Znesek", Double(truncating: item.expense as NSNumber))
                    )
                    .foregroundStyle(Color("negativeColor"))
                }
                .frame(height: 200)
                .cardStyle()

                Text("Projekcija do konca meseca: \(projectedExpense.formatted(.currency(code: "EUR")))")
                    .font(.system(.body, design: .monospaced))
                    .cardStyle()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Zadnje transakcije").font(.headline)
                    ForEach(recentTransactions) { transaction in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(transaction.category?.name ?? "Brez kategorije")
                                Spacer()
                                Text(transaction.amount.formatted(.currency(code: "EUR")))
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundStyle(transaction.type == .income ? Color("positiveColor") : Color("negativeColor"))
                            }
                            Text("\(transaction.type.rawValue) • \(transaction.date.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(Color("textSecondary"))
                        }
                    }
                }
                .cardStyle()
            }
            .padding()
        }
        .background(Color("appBackground"))
    }
    private func spent(for category: Category) -> Decimal {
        transactionsThisMonth
            .filter { $0.category == category && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    private func chargeSubscriptionsIfNeeded() {
        for subscription in subscriptions {
            let alreadyCharged = Calendar.current.isDate(subscription.lastChargedMonth, equalTo: Date(), toGranularity: .month)
            let today = Calendar.current.component(.day, from: Date())
            let dayHasArrived = today >= subscription.billingDay
            
            if !alreadyCharged && dayHasArrived {
                let newTransaction = Transaction(amount: subscription.amount, date: Date(), type: .expense, note: "Naročnina: \(subscription.name)", category: subscription.category)
                modelContext.insert(newTransaction)
                subscription.lastChargedMonth = Date()
            }
            
        }
    }
}

struct MonthlyTotal: Identifiable {
    let id = UUID()
    let month: Date
    let income: Decimal
    let expense: Decimal
    
}




