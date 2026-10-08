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
    @Query private var categories: [Category]
    @Query private var goals: [Goal]
    @Query private var subscriptions: [Subscription]
    @Environment(\.modelContext) private var modelContext
    @State private var showingImporter = false
    @State private var pendingBackup: BackupData? = nil
    @State private var importError: String? = nil
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

    private func handleImport(_ result: Result<URL, Error>) {
        switch result {
        case .failure(let error):
            importError = error.localizedDescription
        case .success(let url):
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let backup = try decoder.decode(BackupData.self, from: data)
                guard backup.version == 1 else {
                    importError = "Nepodprta različica kopije."
                    return
                }
                pendingBackup = backup
            } catch {
                importError = "Datoteke ni mogoče prebrati: \(error.localizedDescription)"
            }
        }
    }

    private func restorePending() {
        guard let backup = pendingBackup else { return }
        do {
            try backup.restore(into: modelContext)
            pendingBackup = nil
        } catch {
            pendingBackup = nil
            importError = "Obnova ni uspela: \(error.localizedDescription)"
        }
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
                    )
                    {
                        Label("Izvozi transakcije (CSV)", systemImage: "square.and.arrow.up")
                    }
                    ShareLink(
                        item: BackupFile(data: BackupData(
                            categories: categories,
                            transactions: transactions,
                            goals: goals,
                            subscriptions: subscriptions
                        )),
                        preview: SharePreview("MoneyTracker-backup.json")
                    ) {
                        Label("Varnostna kopija (JSON)", systemImage: "externaldrive")
                    }

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Obnovi iz kopije (JSON)", systemImage: "arrow.counterclockwise")
                    }
                }
                .listRowBackground(Color("cardBackground"))
            }
            .scrollContentBackground(.hidden)
            .background(Color("appBackground"))
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                handleImport(result)
            }
            .alert(
                "Obnovi podatke?",
                isPresented: Binding(
                    get: { pendingBackup != nil },
                    set: { if !$0 { pendingBackup = nil } }
                )
            ) {
                Button("Obnovi in zamenjaj", role: .destructive) { restorePending() }
                Button("Prekliči", role: .cancel) { pendingBackup = nil }
            } message: {
                Text("Vsi trenutni podatki bodo zamenjani s podatki iz kopije (\(pendingBackup?.transactions.count ?? 0) transakcij).")
            }
            .alert(
                "Napaka pri uvozu",
                isPresented: Binding(
                    get: { importError != nil },
                    set: { if !$0 { importError = nil } }
                )
            ) {
                Button("V redu", role: .cancel) {}
            } message: {
                Text(importError ?? "")
            }
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
