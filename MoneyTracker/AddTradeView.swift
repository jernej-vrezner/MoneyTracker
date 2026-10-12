//
//  AddTradeView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 12. 10. 2026.
//

import SwiftUI
import SwiftData

struct AddTradeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var investments: [Investment]

    let presetInvestment: Investment?
    let tradeToEdit: InvestmentTrade?

    @State private var query = ""
    @State private var results: [YahooSearchResult] = []
    @State private var selected: YahooSearchResult? = nil
    @State private var quote: YahooQuote? = nil
    @State private var isBuy = true
    @State private var quantityText = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var showingDatePicker = false
    @State private var searchFailed = false

    init(investment: Investment? = nil, trade: InvestmentTrade? = nil) {
        self.tradeToEdit = trade
        self.presetInvestment = trade?.investment ?? investment
        if let trade {
            _isBuy = State(initialValue: trade.isBuy)
            _quantityText = State(initialValue: "\(trade.quantity)".replacingOccurrences(of: ".", with: ","))
            _amountText = State(initialValue: "\(trade.totalAmount)".replacingOccurrences(of: ".", with: ","))
            _date = State(initialValue: trade.date)
        }
    }

    private func parse(_ text: String) -> Decimal {
        Decimal(string: text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var quantity: Decimal { parse(quantityText) }
    private var amount: Decimal { parse(amountText) }

    private var existingInvestment: Investment? {
        if let presetInvestment { return presetInvestment }
        guard let selected else { return nil }
        return investments.first { $0.symbol == selected.symbol }
    }

    private var heldQuantity: Decimal {
        (existingInvestment?.trades ?? [])
            .filter { $0 !== tradeToEdit }
            .reduce(Decimal(0)) { $0 + ($1.isBuy ? $1.quantity : -$1.quantity) }
    }

    private var canSave: Bool {
        guard presetInvestment != nil || selected != nil else { return false }
        guard quantity > 0, amount > 0 else { return false }
        return isBuy || quantity <= heldQuantity
    }

    var body: some View {
        NavigationStack {
            Form {
                if let presetInvestment {
                    Section(header: sectionTitle("PAPIR")) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(presetInvestment.name)
                                .foregroundStyle(Color("textPrimary"))
                            Text(presetInvestment.symbol)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(Color("textSecondary"))
                        }
                    }
                    .listRowBackground(Color("cardBackground"))
                } else {
                    Section(header: sectionTitle("PAPIR")) {
                        if let selected {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(selected.name)
                                        .foregroundStyle(Color("textPrimary"))
                                    Text(priceLine(for: selected))
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundStyle(Color("textSecondary"))
                                }
                                Spacer()
                                Button("Zamenjaj") {
                                    self.selected = nil
                                    quote = nil
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(Color.accentColor)
                            }
                        } else {
                            TextField("Išči po imenu (Apple, VWCE, Bitcoin)", text: $query)
                                .autocorrectionDisabled()
                            ForEach(results) { result in
                                Button {
                                    select(result)
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(result.name)
                                            .foregroundStyle(Color("textPrimary"))
                                        Text("\(result.symbol) · \(result.kind.title) · \(result.exchange)")
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundStyle(Color("textSecondary"))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            if searchFailed {
                                Text("Iskanje ni uspelo. Preveri internetno povezavo.")
                                    .font(.caption)
                                    .foregroundStyle(Color("negativeColor"))
                            }
                        }
                    }
                    .listRowBackground(Color("cardBackground"))
                }

                Section(header: sectionTitle("VRSTA")) {
                    Picker("Vrsta", selection: $isBuy) {
                        Text("Nakup").tag(true)
                        Text("Prodaja").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color("cardBackground"))

                Section(
                    header: sectionTitle("KOLIČINA"),
                    footer: Text(isBuy ? "" : "Na voljo za prodajo: \(heldQuantity.formatted())")
                ) {
                    TextField("0", text: $quantityText)
                        .keyboardType(.decimalPad)
                }
                .listRowBackground(Color("cardBackground"))

                Section(
                    header: sectionTitle(isBuy ? "SKUPNO PLAČANO (EUR)" : "SKUPNO PREJETO (EUR)"),
                    footer: Text(pricePerUnitText)
                ) {
                    TextField("0,00 €", text: $amountText)
                        .keyboardType(.decimalPad)
                }
                .listRowBackground(Color("cardBackground"))

                Section(header: sectionTitle("DATUM")) {
                    Button {
                        showingDatePicker = true
                    } label: {
                        HStack {
                            Text(date.formatted(.dateTime.day().month(.wide).year()))
                                .foregroundStyle(Color("textPrimary"))
                            Spacer()
                            Image(systemName: "calendar")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showingDatePicker) {
                        DatePicker("Datum", selection: $date, in: ...Date(), displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding()
                            .frame(minWidth: 320, minHeight: 360)
                    }
                }
                .listRowBackground(Color("cardBackground"))
            }
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
            .navigationTitle(tradeToEdit != nil ? "Uredi transakcijo" : (isBuy ? "Nov nakup" : "Nova prodaja"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Prekliči") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Shrani") { save() }
                        .disabled(!canSave)
                }
            }
            .task(id: query) {
                await runSearch()
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(.caption2, design: .monospaced))
            .foregroundStyle(Color("textSecondary"))
    }

    private var pricePerUnitText: String {
        guard quantity > 0, amount > 0 else { return "" }
        return "Cena na kos: \((amount / quantity).formatted(.currency(code: "EUR")))"
    }

    private func priceLine(for result: YahooSearchResult) -> String {
        guard let quote else { return "\(result.symbol) · pridobivam ceno ..." }
        return "\(result.symbol) · \(quote.price.formatted()) \(quote.currency)"
    }

    private func runSearch() async {
        guard presetInvestment == nil, selected == nil else { return }
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            results = []
            return
        }
        try? await Task.sleep(for: .milliseconds(400))
        if Task.isCancelled { return }
        do {
            results = try await YahooFinance.search(trimmed)
            searchFailed = false
        } catch {
            if Task.isCancelled { return }
            results = []
            searchFailed = true
        }
    }

    private func select(_ result: YahooSearchResult) {
        selected = result
        results = []
        quote = nil
        Task {
            quote = try? await YahooFinance.quote(symbol: result.symbol)
        }
    }

    private func save() {
        if let trade = tradeToEdit {
            trade.isBuy = isBuy
            trade.quantity = quantity
            trade.totalAmount = amount
            trade.date = date
            dismiss()
            return
        }
        let investment: Investment
        if let existing = existingInvestment {
            investment = existing
        } else if let selected {
            investment = Investment(
                symbol: selected.symbol,
                name: selected.name,
                kind: selected.kind,
                currency: quote?.currency ?? "EUR"
            )
            modelContext.insert(investment)
        } else {
            return
        }

        if let quote {
            investment.lastPrice = quote.price
            investment.previousClose = quote.previousClose
            investment.currency = quote.currency
            investment.lastUpdated = Date()
        }

        let trade = InvestmentTrade(date: date, isBuy: isBuy, quantity: quantity, totalAmount: amount)
        modelContext.insert(trade)
        trade.investment = investment
        dismiss()
    }
}
