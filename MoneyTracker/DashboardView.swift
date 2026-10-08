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
    @State private var showingBudgetEdit = false
    @State private var showingBudgetInfo = false
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @Query private var subscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext

    var transactionsThisMonth: [Transaction] {
        transactions.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
    }

    var totalIncome: Decimal {
        transactionsThisMonth.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpense: Decimal {
        transactionsThisMonth.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var totalInvestment: Decimal {
        transactionsThisMonth.filter { $0.type == .investment }.reduce(0) { $0 + $1.amount }
    }

    var net: Decimal {
        totalIncome - totalExpense
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

    var projectedExpense: Decimal {
        let calendar = Calendar.current
        let daysElapsed = calendar.component(.day, from: Date())
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())!.count
        guard daysElapsed > 0 else { return 0 }
        return totalExpense / Decimal(daysElapsed) * Decimal(daysInMonth)
    }

    var recentTransactions: [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(5))
    }

    var totalBudget: Decimal {
        categories.reduce(0) { $0 + $1.monthlyLimit }
    }

    var budgetPercentUsed: Double {
        guard totalBudget > 0 else { return 0 }
        return Double(truncating: (totalExpense / totalBudget) as NSNumber)
    }

    var plannedPercent: Double {
        let calendar = Calendar.current
        let daysElapsed = calendar.component(.day, from: Date())
        let daysInMonth = calendar.range(of: .day, in: .month, for: Date())!.count
        return Double(daysElapsed) / Double(daysInMonth)
    }

    var maxFlowAmount: Decimal {
        max(totalIncome, totalExpense, 1)
    }

    var incomeRatio: Double {
        Double(truncating: (totalIncome / maxFlowAmount) as NSNumber)
    }

    var expenseRatio: Double {
        Double(truncating: (totalExpense / maxFlowAmount) as NSNumber)
    }

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "Pregled")

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("PORABA VS. BUDGET")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Color("textSecondary"))
                            Button {
                                showingBudgetInfo = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundStyle(Color("textSecondary"))
                            }
                            .popover(isPresented: $showingBudgetInfo) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Kaj to pomeni?").font(.headline)
                                    Text("Prikazuje porabo glede na skupni mesečni budget vseh kategorij. Projekcija oceni skupno porabo do konca meseca, če nadaljuješ s trenutnim tempom.")
                                        .font(.subheadline)
                                }
                                .padding()
                                .frame(maxWidth: 280)
                            }
                            Spacer()
                            Text("dan \(Calendar.current.component(.day, from: Date()))/\(Calendar.current.range(of: .day, in: .month, for: Date())!.count)")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Color("textSecondary"))
                        }
                        HStack(alignment: .lastTextBaseline, spacing: 6) {
                            Text(totalExpense.formatted(.currency(code: "EUR")))
                                .font(.system(.largeTitle, design: .monospaced).weight(.bold))
                                .foregroundStyle(Color("textPrimary"))
                            Text("/ \(totalBudget.formatted(.currency(code: "EUR")))")
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(Color("textSecondary"))
                        }
                        CategoryProgressBar(progress: budgetPercentUsed, color: Color.accentColor)
                        HStack {
                            Text("\(Int(budgetPercentUsed * 100))% porabljeno")
                            Spacer()
                            Text("načrtovano \(Int(plannedPercent * 100))%")
                        }
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(Color("textSecondary"))
                        Text(budgetPercentUsed > plannedPercent
                             ? "Za \(Int((budgetPercentUsed - plannedPercent) * 100)) % pred načrtom. Če želiš ostati v okviru, imaš do \(Calendar.current.range(of: .day, in: .month, for: Date())!.count). \(Calendar.current.component(.month, from: Date())). na voljo \((totalBudget - totalExpense).formatted(.currency(code: "EUR")))."
                             : "V okviru načrta. Če želiš ostati v okviru, imaš do \(Calendar.current.range(of: .day, in: .month, for: Date())!.count). \(Calendar.current.component(.month, from: Date())). na voljo \((totalBudget - totalExpense).formatted(.currency(code: "EUR")))."
                        )
                        .font(.caption)
                        .foregroundStyle(Color("textPrimary"))
                        .padding(12)
                        .background(Color.white.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding()
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 26))

                    VStack(alignment: .leading, spacing: 14) {
                        Text("PRILIVI IN ODLIVI")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(Color("textSecondary"))

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Prilivi").foregroundStyle(Color("textSecondary"))
                                Spacer()
                                Text(totalIncome.formatted(.currency(code: "EUR")))
                                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                    .foregroundStyle(Color("positiveColor"))
                            }
                            CategoryProgressBar(progress: incomeRatio, color: Color("positiveColor"))
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Odlivi").foregroundStyle(Color("textSecondary"))
                                Spacer()
                                Text(totalExpense.formatted(.currency(code: "EUR")))
                                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                    .foregroundStyle(Color("negativeColor"))
                            }
                            CategoryProgressBar(progress: expenseRatio, color: Color("negativeColor"))
                        }

                        Divider()

                        HStack {
                            Text("Razlika").foregroundStyle(Color("textSecondary"))
                            Spacer()
                            Text(net.formatted(.currency(code: "EUR")))
                                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                                .foregroundStyle(Color("textPrimary"))
                        }

                        HStack {
                            Text("Investicije").foregroundStyle(Color("textSecondary"))
                            Spacer()
                            Text(totalInvestment.formatted(.currency(code: "EUR")))
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Color("textSecondary"))
                        }
                    }
                    .cardStyle()

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("BUDGET PO KATEGORIJAH")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Color("textSecondary"))
                            Spacer()
                            Text("\(totalExpense.formatted(.currency(code: "EUR"))) / \(totalBudget.formatted(.currency(code: "EUR")))")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(Color("textSecondary"))
                            Button {
                                showingBudgetEdit = true
                            } label: {
                                Image(systemName: "pencil")
                                    .frame(width: 26, height: 26)
                                    .background(Color("appBackground"))
                                    .clipShape(Circle())
                            }
                        }
                        ForEach(categories) { category in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    CategoryIconBadge(icon: category.icon, color: category.color.color)
                                    Text(category.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color("textPrimary"))
                                    Spacer()
                                    Text("\(spent(for: category).formatted(.currency(code: "EUR"))) / \(category.monthlyLimit.formatted(.currency(code: "EUR")))")
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(spent(for: category) > category.monthlyLimit ? Color("negativeColor") : category.color.color)
                                }
                                CategoryProgressBar(
                                    progress: category.progress(spent: spent(for: category)),
                                    color: spent(for: category) > category.monthlyLimit ? Color("negativeColor") : category.color.color
                                )
                            }
                        }
                    }
                    .cardStyle()
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Zadnje transakcije").font(.headline)
                        ForEach(recentTransactions) { transaction in
                            VStack(alignment: .leading) {
                                HStack {
                                    CategoryIconBadge(
                                        icon: transaction.category?.icon ?? "questionmark.circle",
                                        color: transaction.category?.color.color ?? Color("textSecondary")
                                    )
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
        }
        .background(Color("appBackground"))
        .onAppear {
            chargeSubscriptionsIfNeeded()
        }
        .sheet(isPresented: $showingBudgetEdit) {
            BudgetEditView()
        }
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
            let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())!.count
            let dayHasArrived = today >= min(subscription.billingDay, daysInMonth)

            if !alreadyCharged && dayHasArrived {
                let noteText = subscription.note.isEmpty ? "Naročnina: \(subscription.name)" : "Naročnina: \(subscription.name) · \(subscription.note)"
                let newTransaction = Transaction(amount: subscription.amount, date: Date(), type: .expense, note: noteText, category: subscription.category)
                modelContext.insert(newTransaction)
                newTransaction.subcategory = subscription.subcategory
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
