//
//  SettingsView.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 8. 10. 2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TransactionsCSV: Transferable {
    let text: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { csv in
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("MoneyTracker-transakcije.csv")
            try Data(csv.text.utf8).write(to: url)
            return SentTransferredFile(url)
        }
    }
}

struct SettingsView: View {
    @AppStorage("appearance") private var appearance = "system"
    @Query private var transactions: [Transaction]
    @Environment(\.dismiss) private var dismiss

    private var csvText: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        var lines = ["Datum,Tip,Znesek,Kategorija,Podkategorija,Opomba"]
        for transaction in transactions.sorted(by: { $0.date < $1.date }) {
            let fields = [
                formatter.string(from: transaction.date),
                transaction.type.rawValue,
                "\(transaction.amount)",
                transaction.category?.name ?? "",
                transaction.subcategory?.name ?? "",
                transaction.note
            ]
            lines.append(fields.map(csvEscape).joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("VIDEZ").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary"))) {
                    Picker("Videz", selection: $appearance) {
                        Text("Sistem").tag("system")
                        Text("Svetlo").tag("light")
                        Text("Temno").tag("dark")
                    }
                    .pickerStyle(.segmented)
                }
                .listRowBackground(Color("cardBackground"))

                Section(
                    header: Text("PODATKI").font(.system(.caption2, design: .monospaced)).foregroundStyle(Color("textSecondary")),
                    footer: Text("Izvoz vsebuje \(transactions.count) transakcij (CSV, odpre se tudi v Excelu ali Številkah).")
                ) {
                    ShareLink(
                        item: TransactionsCSV(text: csvText),
                        preview: SharePreview("MoneyTracker-transakcije.csv")
                    ) {
                        Label("Izvozi transakcije (CSV)", systemImage: "square.and.arrow.up")
                    }
                }
                .listRowBackground(Color("cardBackground"))
            }
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
            .navigationTitle("Nastavitve")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Končaj") { dismiss() }
                }
            }
        }
    }
}
