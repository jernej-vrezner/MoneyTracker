//
//  InvestmentDetailView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 12. 10. 2026.
//

import SwiftUI
import SwiftData
import Charts

struct InvestmentDetailView: View {
    let investment: Investment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("fxRates") private var ratesRaw = ""
    @State private var showingAddTrade = false
    @State private var tradeToEdit: InvestmentTrade? = nil
    @State private var priceRange: PriceRange = .year
    @State private var pricePoints: [PricePoint] = []
    @State private var historyFailed = false

    private var summary: HoldingSummary {
        investment.summary(eurRate: FXStore.decode(ratesRaw)[investment.currency] ?? 0)
    }

    private var sortedTrades: [InvestmentTrade] {
        (investment.trades ?? []).sorted { $0.date > $1.date }
    }

    private var averageCost: Decimal {
        guard summary.quantity > 0 else { return 0 }
        return summary.costBasis / summary.quantity
    }

    private func euro(_ value: Decimal) -> String {
        value.formatted(.currency(code: "EUR"))
    }

    private func statRow(_ label: String, _ value: String, color: Color = Color("textPrimary")) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Color("textSecondary"))
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .foregroundStyle(color)
        }
    }

    private var rangeChangePercent: Double? {
        guard let first = pricePoints.first?.close, let last = pricePoints.last?.close, first > 0 else { return nil }
        return (last - first) / first * 100
    }

    private var chartColor: Color {
        (rangeChangePercent ?? 0) >= 0 ? Color("positiveColor") : Color("negativeColor")
    }

    private func loadHistory() async {
        do {
            pricePoints = try await YahooFinance.history(symbol: investment.symbol, range: priceRange)
            historyFailed = false
        } catch {
            if Task.isCancelled { return }
            pricePoints = []
            historyFailed = true
        }
    }

    private var priceChartSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CENA (\(investment.currency))")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(Color("textSecondary"))
                Spacer()
                if let change = rangeChangePercent {
                    Text((change >= 0 ? "+" : "") + change.formatted(.number.precision(.fractionLength(1))) + " %")
                        .font(.system(.caption, design: .monospaced).weight(.semibold))
                        .foregroundStyle(chartColor)
                }
            }

            if pricePoints.isEmpty {
                Text(historyFailed ? "Zgodovine cen ni mogoče naložiti." : "Nalagam ...")
                    .font(.caption)
                    .foregroundStyle(Color("textSecondary"))
                    .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                Chart(pricePoints) { point in
                    AreaMark(
                        x: .value("Datum", point.date),
                        y: .value("Cena", point.close)
                    )
                    .foregroundStyle(chartColor.opacity(0.12))
                    LineMark(
                        x: .value("Datum", point.date),
                        y: .value("Cena", point.close)
                    )
                    .foregroundStyle(chartColor)
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3))
                }
                .frame(height: 160)
            }

            Picker("Obdobje", selection: $priceRange) {
                ForEach(PriceRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 6)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    priceChartSection
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: Text(investment.symbol).font(.system(.caption2, design: .monospaced))) {
                    statRow("Količina", summary.quantity.formatted())
                    statRow("Trenutna cena", euro(summary.priceEUR))
                    statRow("Povprečna nabavna cena", euro(averageCost))
                    statRow("Vložek", euro(summary.costBasis))
                    statRow("Vrednost", euro(summary.value))
                    statRow(
                        "Dobiček / izguba",
                        (summary.profit >= 0 ? "+" : "") + euro(summary.profit),
                        color: summary.profit >= 0 ? Color("positiveColor") : Color("negativeColor")
                    )
                    if summary.realized != 0 {
                        statRow(
                            "Realiziran dobiček",
                            (summary.realized >= 0 ? "+" : "") + euro(summary.realized),
                            color: summary.realized >= 0 ? Color("positiveColor") : Color("negativeColor")
                        )
                    }
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: Text("TRANSAKCIJE").font(.system(.caption2, design: .monospaced))) {
                    ForEach(sortedTrades) { trade in
                        HStack(spacing: 12) {
                            Image(systemName: trade.isBuy ? "arrow.down.left" : "arrow.up.right")
                                .foregroundStyle(trade.isBuy ? Color("positiveColor") : Color("negativeColor"))
                                .frame(width: 28, height: 28)
                                .background((trade.isBuy ? Color("positiveColor") : Color("negativeColor")).opacity(0.15))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(trade.isBuy ? "Nakup" : "Prodaja") · \(trade.quantity.formatted()) kos")
                                    .foregroundStyle(Color("textPrimary"))
                                Text(trade.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(Color("textSecondary"))
                            }

                            Spacer()

                            Text(euro(trade.totalAmount))
                                .font(.system(.subheadline, design: .monospaced))
                                .foregroundStyle(Color("textPrimary"))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { tradeToEdit = trade }
                    }
                    .onDelete(perform: deleteTrades)

                    Button {
                        showingAddTrade = true
                    } label: {
                        Label("Nov nakup ali prodaja", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Color("textSecondary"))
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color("cardBackground"))
            }
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
            .task(id: priceRange) {
                await loadHistory()
            }
            .navigationTitle(investment.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Končaj") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddTrade) {
                AddTradeView(investment: investment)
            }
            .sheet(item: $tradeToEdit) { trade in
                AddTradeView(trade: trade)
            }
        }
    }

    private func deleteTrades(offsets: IndexSet) {
        let trades = sortedTrades
        for index in offsets {
            modelContext.delete(trades[index])
        }
    }
}
