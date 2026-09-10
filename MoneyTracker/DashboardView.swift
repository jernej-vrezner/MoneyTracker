//
//  DashboardView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 10. 9. 2026.
//

import SwiftUI
import SwiftData


struct DashboardView: View {
    @Query private var transactions: [Transaction]

    var transactionsThisMonth: [Transaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    var totalIncome: Decimal {
        transactionsThisMonth.filter{$0.type == .income}.reduce(0) {$0 + $1.amount}
    }

    var totalExpense: Decimal {
        transactionsThisMonth.filter{$0.type == .expense}.reduce(0) {$0 + $1.amount}
    }

    var totalInvestment: Decimal {
        transactionsThisMonth.filter{$0.type == .investment}.reduce(0) {$0 + $1.amount}
    }
    
    var net: Decimal {
        totalIncome - totalExpense
    }
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Prilivi: \(totalIncome.formatted(.currency(code: "EUR")))")
            Text("Odlivi: \(totalExpense.formatted(.currency(code: "EUR")))")
            Text("Investicije: \(totalInvestment.formatted(.currency(code: "EUR")))")
            Text("Neto: \(net.formatted(.currency(code: "EUR")))")
        }
        
    }
}
