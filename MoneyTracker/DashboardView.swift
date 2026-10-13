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
    @Query(sort: \Goal.deadline) private var goals: [Goal]
    @Query private var investments: [Investment]
    @AppStorage("fxRates") private var fxRatesRaw = ""
    @State private var visibleGoalID: PersistentIdentifier? = nil
    @State private var investmentRange: PriceRange = .sixMonths
    @State private var investmentPoints: [PortfolioPoint] = []
    @State private var showingBudgetEdit = false
    @State private var showingBudgetInfo = false
    @State private var showingDashboardEdit = false
    @AppStorage("dashboardOrder") private var orderRaw = ""
    @AppStorage("dashboardHidden") private var hiddenRaw = ""
    @Query private var transactions: [Transaction]
    @Query private var categories: [Category]
    @Query private var subscriptions: [Subscription]
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @Environment(\.modelContext) private var modelContext

    private var visibleCards: [DashboardCard] {
        let hidden = DashboardCard.decodeSet(hiddenRaw)
        return DashboardCard.decode(orderRaw).filter { !hidden.contains($0) }
    }

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

    var lastTwelveMonthsExpense: [MonthlyTotal] {
        (0..<12).reversed().map { offset in
            let monthDate = Calendar.current.date(byAdding: .month, value: -offset, to: Date())!
            let expense = transactions
                .filter {
                    $0.type == .expense
                    && Calendar.current.isDate($0.date, equalTo: monthDate, toGranularity: .month)
                }
                .reduce(0) { $0 + $1.amount }
            return MonthlyTotal(month: monthDate, income: 0, expense: expense)
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
        NavigationStack {
        VStack(spacing: 0) {
            ScreenHeader(title: "Pregled", onEdit: { showingDashboardEdit = true })

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(visibleCards) { card in
                        cardView(card)
                    }
                }
                .padding()
            }
        }
        .background(Color("appBackground"))
        .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            chargeSubscriptionsIfNeeded()
        }
        .sheet(isPresented: $showingBudgetEdit) {
            BudgetEditView()
        }
        .sheet(isPresented: $showingDashboardEdit) {
            DashboardEditView()
        }
    }

    @ViewBuilder
    private func cardView(_ card: DashboardCard) -> some View {
        switch card {
        case .budget: heroCard
        case .accounts: accountsCard
        case .flows: flowsCard
        case .projection: projectionCard
        case .categories: categoriesCard
        case .recent: recentCard
        case .goals: goalsCard
        case .investments: investmentsCard
        }
    }

    private var accountsTotal: Decimal {
        accounts.filter { $0.includeInTotal }.reduce(Decimal(0)) { $0 + $1.balance }
    }

    private var accountsCard: some View {
        NavigationLink {
            AccountsView()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("RAČUNI")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(Color("textSecondary"))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Color("textSecondary"))
                }

                if accounts.isEmpty {
                    Text("Dodaj prvi račun")
                        .font(.subheadline)
                        .foregroundStyle(Color.accentColor)
                } else {
                    Text(accountsTotal.formatted(.currency(code: "EUR")))
                        .font(.system(.title, design: .monospaced).weight(.bold))
                        .foregroundStyle(Color("textPrimary"))

                    ForEach(accounts.prefix(3)) { account in
                        HStack(spacing: 10) {
                            CategoryIconBadge(icon: account.kind.iconName, color: account.color.color)
                            Text(account.name)
                                .font(.subheadline)
                                .foregroundStyle(Color("textPrimary"))
                                .lineLimit(1)
                            Spacer()
                            Text(account.balance.formatted(.currency(code: "EUR")))
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(account.balance < 0 ? Color("negativeColor") : Color("textPrimary"))
                        }
                    }

                    if accounts.count > 3 {
                        Text("in še \(accounts.count - 3)")
                            .font(.caption)
                            .foregroundStyle(Color("textSecondary"))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
    private var portfolioSummaries: [HoldingSummary] {
        let rates = FXStore.decode(fxRatesRaw)
        return investments
            .map { $0.summary(eurRate: rates[$0.currency] ?? 0) }
            .filter { $0.quantity > 0 }
    }

    private var portfolioValue: Decimal {
        portfolioSummaries.reduce(Decimal(0)) { $0 + $1.value }
    }

    private var portfolioDayChange: Decimal {
        portfolioSummaries.reduce(Decimal(0)) { $0 + $1.dayChangeEUR }
    }

    private func goalPage(_ goal: Goal) -> some View {
        HStack(alignment: .top, spacing: 16) {
            CircularProgressRing(progress: goal.progress, color: Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.headline)
                    .foregroundStyle(Color("textPrimary"))
                    .lineLimit(1)
                Text(goal.savedAmount.formatted(.currency(code: "EUR")))
                    .font(.system(.title3, design: .monospaced).weight(.bold))
                    .foregroundStyle(Color("textPrimary"))
                Text("od \(goal.targetAmount.formatted(.currency(code: "EUR"))) · ostane \(goal.remaining.formatted(.currency(code: "EUR")))")
                    .font(.caption)
                    .foregroundStyle(Color("textSecondary"))
                Text("mesečno \(goal.monthlyNeeded.formatted(.currency(code: "EUR"))) · rok \(goal.deadline.formatted(.dateTime.month(.abbreviated).year()))")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color("textSecondary"))
            }

            Spacer(minLength: 0)
        }
    }

    private var goalsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("CILJI")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("textSecondary"))

            if goals.isEmpty {
                Text("Še nimaš ciljev. Dodaj jih v zavihku Varčevanje.")
                    .font(.caption)
                    .foregroundStyle(Color("textSecondary"))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 0) {
                        ForEach(goals) { goal in
                            goalPage(goal)
                                .containerRelativeFrame(.horizontal)
                                .id(goal.persistentModelID)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.paging)
                .scrollPosition(id: $visibleGoalID)

                if goals.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(goals) { goal in
                            Circle()
                                .fill(goal.persistentModelID == (visibleGoalID ?? goals.first?.persistentModelID)
                                      ? Color.accentColor
                                      : Color("textSecondary").opacity(0.3))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var portfolioDayChangePercent: Double {
        let previous = portfolioValue - portfolioDayChange
        guard previous > 0 else { return 0 }
        return Double(truncating: (portfolioDayChange / previous) as NSNumber) * 100
    }

    private var investmentHistoryKey: String {
        let tradeCount = investments.reduce(0) { $0 + ($1.trades?.count ?? 0) }
        return "\(investmentRange.rawValue)-\(investments.count)-\(tradeCount)-\(fxRatesRaw)"
    }

    private var investmentChartColor: Color {
        guard let first = investmentPoints.first?.value, let last = investmentPoints.last?.value else {
            return Color.accentColor
        }
        return last >= first ? Color("positiveColor") : Color("negativeColor")
    }

    private func loadInvestmentHistory() async {
        let inputs = investments.map { investment in
            HoldingInput(
                symbol: investment.symbol,
                currency: investment.currency,
                trades: (investment.trades ?? []).map { trade in
                    (date: trade.date, quantity: trade.isBuy ? trade.quantity : -trade.quantity)
                }
            )
        }
        guard !inputs.isEmpty else {
            investmentPoints = []
            return
        }
        let points = await PortfolioHistory.build(
            holdings: inputs,
            range: investmentRange,
            rates: FXStore.decode(fxRatesRaw)
        )
        if Task.isCancelled { return }
        investmentPoints = points
    }

    private var investmentsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NALOŽBE")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("textSecondary"))

            if investments.isEmpty {
                Text("Še nimaš naložb. Dodaj jih v zavihku Varčevanje.")
                    .font(.caption)
                    .foregroundStyle(Color("textSecondary"))
            } else {
                Text(portfolioValue.formatted(.currency(code: "EUR")))
                    .font(.system(.title, design: .monospaced).weight(.bold))
                    .foregroundStyle(Color("textPrimary"))

                HStack(spacing: 6) {
                    Text((portfolioDayChange >= 0 ? "+" : "") + portfolioDayChange.formatted(.currency(code: "EUR")))
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundStyle(portfolioDayChange >= 0 ? Color("positiveColor") : Color("negativeColor"))
                    Text("danes · " + (portfolioDayChangePercent >= 0 ? "+" : "") + portfolioDayChangePercent.formatted(.number.precision(.fractionLength(1))) + " %")
                        .font(.caption)
                        .foregroundStyle(Color("textSecondary"))
                }

                if investmentPoints.count > 1 {
                    Chart(investmentPoints) { point in
                        AreaMark(
                            x: .value("Datum", point.date),
                            y: .value("Vrednost", point.value)
                        )
                        .foregroundStyle(investmentChartColor.opacity(0.15))
                        LineMark(
                            x: .value("Datum", point.date),
                            y: .value("Vrednost", point.value)
                        )
                        .foregroundStyle(investmentChartColor)
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 80)
                }

                Picker("Obdobje", selection: $investmentRange) {
                    ForEach(PriceRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .task(id: investmentHistoryKey) {
            await loadInvestmentHistory()
        }
    }

    private var heroCard: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private var flowsCard: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var projectionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PROJEKCIJA")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("textSecondary"))

            Text(projectedExpense.formatted(.currency(code: "EUR")))
                .font(.system(.title, design: .monospaced).weight(.bold))
                .foregroundStyle(projectedExpense > totalBudget && totalBudget > 0 ? Color("negativeColor") : Color("textPrimary"))

            Text("ob trenutnem tempu porabe do konca meseca")
                .font(.caption)
                .foregroundStyle(Color("textSecondary"))

            Chart(Array(lastTwelveMonthsExpense.enumerated()), id: \.offset) { index, item in
                BarMark(
                    x: .value("Mesec", index),
                    y: .value("€", Double(truncating: item.expense as NSNumber))
                )
                .foregroundStyle(index == 11 ? Color.accentColor : Color("textSecondary").opacity(0.3))
                .cornerRadius(3)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 60)

            Text("zadnjih 12 mesecev")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("textSecondary"))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var categoriesCard: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var recentCard: some View {
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
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
                newTransaction.account = subscription.account
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
