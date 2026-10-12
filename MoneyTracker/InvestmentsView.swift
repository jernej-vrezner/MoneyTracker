import SwiftUI
import SwiftData

struct InvestmentsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var investments: [Investment]
    @AppStorage("fxRates") private var ratesRaw = ""
    @State private var showingAddTrade = false
    @State private var detailTarget: Investment? = nil
    @State private var refreshFailed = false

    private var rates: [String: Decimal] { FXStore.decode(ratesRaw) }

    private var summaries: [HoldingSummary] {
        investments
            .map { $0.summary(eurRate: rates[$0.currency] ?? 0) }
            .filter { $0.quantity > 0 }
            .sorted { $0.value > $1.value }
    }

    private var totalValue: Decimal {
        summaries.reduce(Decimal(0)) { $0 + $1.value }
    }

    private var totalDayChange: Decimal {
        summaries.reduce(Decimal(0)) { $0 + $1.dayChangeEUR }
    }

    private var dayChangePercent: Double {
        let previous = totalValue - totalDayChange
        guard previous > 0 else { return 0 }
        return Double(truncating: (totalDayChange / previous) as NSNumber) * 100
    }

    private var lastUpdate: Date? {
        investments.compactMap(\.lastUpdated).max()
    }

    private func share(of kind: AssetKind) -> Double {
        guard totalValue > 0 else { return 0 }
        let kindValue = summaries.filter { $0.investment.kind == kind }.reduce(Decimal(0)) { $0 + $1.value }
        return Double(truncating: (kindValue / totalValue) as NSNumber)
    }

    private func percentText(_ value: Double) -> String {
        (value >= 0 ? "+" : "") + value.formatted(.number.precision(.fractionLength(1))) + " %"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                portfolioCard
                holdingsCard

                Button {
                    showingAddTrade = true
                } label: {
                    HStack {
                        Spacer()
                        Label("Nov nakup ali prodaja", systemImage: "plus")
                            .foregroundStyle(Color("textSecondary"))
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .cardStyle()
                }
                .buttonStyle(.plain)

                footer
            }
            .padding()
        }
        .background(Color("appBackground"))
        .refreshable {
            await refresh()
        }
        .task {
            await refresh()
        }
        .sheet(isPresented: $showingAddTrade) {
            AddTradeView()
        }
        .sheet(item: $detailTarget) { investment in
            InvestmentDetailView(investment: investment)
        }
    }

    private var portfolioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("VREDNOST PORTFELJA")
                .font(.system(.caption2, design: .monospaced))
                .foregroundStyle(Color("textSecondary"))

            Text(totalValue.formatted(.currency(code: "EUR")))
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .foregroundStyle(Color("textPrimary"))

            HStack(spacing: 6) {
                Text((totalDayChange >= 0 ? "+" : "") + totalDayChange.formatted(.currency(code: "EUR")))
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(totalDayChange >= 0 ? Color("positiveColor") : Color("negativeColor"))
                Text("danes · \(percentText(dayChangePercent))")
                    .font(.caption)
                    .foregroundStyle(Color("textSecondary"))
            }

            if totalValue > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        ForEach(AssetKind.allCases, id: \.self) { kind in
                            let fraction = share(of: kind)
                            if fraction > 0 {
                                Rectangle()
                                    .fill(kind.color)
                                    .frame(width: geometry.size.width * fraction)
                            }
                        }
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())

                HStack(spacing: 12) {
                    ForEach(AssetKind.allCases, id: \.self) { kind in
                        let fraction = share(of: kind)
                        if fraction > 0 {
                            HStack(spacing: 4) {
                                Circle().fill(kind.color).frame(width: 8, height: 8)
                                Text("\(kind.title) \(Int((fraction * 100).rounded())) %")
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(Color("textSecondary"))
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 26))
    }

    private var holdingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if summaries.isEmpty {
                Text("Še nimaš naložb. Dodaj prvi nakup.")
                    .font(.caption)
                    .foregroundStyle(Color("textSecondary"))
                    .padding(.vertical, 8)
            } else {
                ForEach(summaries) { summary in
                    holdingRow(summary)
                    if summary.id != summaries.last?.id {
                        Divider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private func holdingRow(_ summary: HoldingSummary) -> some View {
        let investment = summary.investment
        return HStack(spacing: 12) {
            CategoryIconBadge(icon: investment.kind.iconName, color: investment.kind.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(investment.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color("textPrimary"))
                    .lineLimit(1)
                Text("\(summary.quantity.formatted()) kos · \(summary.priceEUR.formatted(.currency(code: "EUR")))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color("textSecondary"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(summary.value.formatted(.currency(code: "EUR")))
                    .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                    .foregroundStyle(Color("textPrimary"))
                if let percent = summary.profitPercent {
                    Text(percentText(percent))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(percent >= 0 ? Color("positiveColor") : Color("negativeColor"))
                }
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture { detailTarget = investment }
        .contextMenu {
            Button(role: .destructive) {
                modelContext.delete(investment)
            } label: {
                Label("Izbriši naložbo", systemImage: "trash")
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 4) {
            if let lastUpdate {
                Text("Podatki prek Yahoo Finance · \(lastUpdate.formatted(date: .omitted, time: .shortened))")
            }
            if refreshFailed {
                Text("Osvežitev ni uspela, prikazane so zadnje znane cene.")
                    .foregroundStyle(Color("negativeColor"))
            }
        }
        .font(.system(.caption2, design: .monospaced))
        .foregroundStyle(Color("textSecondary"))
        .frame(maxWidth: .infinity)
    }

    private func refresh() async {
        var newRates = rates
        var failed = false

        for investment in investments {
            do {
                let quote = try await YahooFinance.quote(symbol: investment.symbol)
                investment.lastPrice = quote.price
                investment.previousClose = quote.previousClose
                investment.currency = quote.currency
                investment.lastUpdated = Date()
                if newRates[quote.currency] == nil || quote.currency != "EUR" {
                    newRates[quote.currency] = try await YahooFinance.eurRate(for: quote.currency)
                }
            } catch {
                failed = true
            }
        }

        ratesRaw = FXStore.encode(newRates)
        refreshFailed = failed
    }
}
