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
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                Text("Prilivi: \(totalIncome.formatted(.currency(code: "EUR")))")
                Text("Odlivi: \(totalExpense.formatted(.currency(code: "EUR")))")
                Text("Investicije: \(totalInvestment.formatted(.currency(code: "EUR")))")
                Text("Neto: \(net.formatted(.currency(code: "EUR")))")
            }
            Chart(categories) { category in
                BarMark(
                    x: .value("Kategorija", category.name),
                    y: .value("Znesek", Double(truncating: spent(for: category) as NSNumber))
                )
            }
            .frame(height: 200)
            
            Chart(lastSixMonths) { item in
                BarMark(
                    x: .value("Mesec", item.month, unit: .month),
                    y: .value("Znesek", Double(truncating: item.income as NSNumber))
                )
                .foregroundStyle(by: .value("Tip", "Prilivi"))

                BarMark(
                    x: .value("Mesec", item.month, unit: .month),
                    y: .value("Znesek", Double(truncating: item.expense as NSNumber))
                )
                .foregroundStyle(by: .value("Tip", "Odlivi"))
            }
            .frame(height: 200)
        }
    }
    private func spent(for category: Category) -> Decimal {
        transactionsThisMonth
            .filter { $0.category == category && $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
}

struct MonthlyTotal: Identifiable {
    let id = UUID()
    let month: Date
    let income: Decimal
    let expense: Decimal
    
}




