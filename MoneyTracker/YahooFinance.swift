//
//  YahooFinance.swift
//  MoneyTracker
//
//  Created by Jernej Vrezner on 12. 10. 2026.
//

import Foundation

struct YahooSearchResult: Identifiable {
    let symbol: String
    let name: String
    let kind: AssetKind
    let exchange: String
    var id: String { symbol }
}

struct YahooQuote {
    let price: Decimal
    let previousClose: Decimal?
    let currency: String
}

private struct SearchResponse: Decodable {
    struct Item: Decodable {
        let symbol: String
        let shortname: String?
        let longname: String?
        let quoteType: String?
        let exchDisp: String?
    }
    let quotes: [Item]
}

struct PricePoint: Identifiable {
    let date: Date
    let close: Double
    var id: Date { date }
}

enum PriceRange: String, CaseIterable {
    case month = "1M"
    case sixMonths = "6M"
    case year = "1L"
    case fiveYears = "5L"

    var yahooRange: String {
        switch self {
        case .month: return "1mo"
        case .sixMonths: return "6mo"
        case .year: return "1y"
        case .fiveYears: return "5y"
        }
    }

    var yahooInterval: String {
        self == .fiveYears ? "1wk" : "1d"
    }
}

private struct HistoryResponse: Decodable {
    struct Chart: Decodable {
        struct Result: Decodable {
            struct Meta: Decodable {
                let currency: String?
            }
            struct Indicators: Decodable {
                struct Quote: Decodable {
                    let close: [Double?]?
                }
                let quote: [Quote]
            }
            let meta: Meta
            let timestamp: [Int]?
            let indicators: Indicators
        }
        let result: [Result]?
    }
    let chart: Chart
}

private struct ChartResponse: Decodable {
    struct Chart: Decodable {
        struct Result: Decodable {
            struct Meta: Decodable {
                let currency: String?
                let regularMarketPrice: Double?
                let previousClose: Double?
                let chartPreviousClose: Double?
            }
            let meta: Meta
        }
        let result: [Result]?
    }
    let chart: Chart
}

enum YahooFinance {
    enum YahooError: Error {
        case badResponse
        case noData
    }

    private static func fetch(_ urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw YahooError.badResponse }
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw YahooError.badResponse
        }
        return data
    }

    private static func toDecimal(_ value: Double) -> Decimal {
        Decimal(string: String(value)) ?? Decimal(value)
    }

    static func search(_ query: String) async throws -> [YahooSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        let data = try await fetch("https://query1.finance.yahoo.com/v1/finance/search?q=\(encoded)&quotesCount=10&newsCount=0")
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)

        return response.quotes.compactMap { item -> YahooSearchResult? in
            let kind: AssetKind
            switch item.quoteType {
            case "EQUITY": kind = .stock
            case "ETF": kind = .etf
            case "CRYPTOCURRENCY": kind = .crypto
            default: return nil
            }
            return YahooSearchResult(
                symbol: item.symbol,
                name: item.longname ?? item.shortname ?? item.symbol,
                kind: kind,
                exchange: item.exchDisp ?? ""
            )
        }
    }

    static func quote(symbol: String) async throws -> YahooQuote {
        guard let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw YahooError.badResponse
        }
        let data = try await fetch("https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1d")
        let response = try JSONDecoder().decode(ChartResponse.self, from: data)
        guard let meta = response.chart.result?.first?.meta,
              let rawPrice = meta.regularMarketPrice else {
            throw YahooError.noData
        }

        var price = toDecimal(rawPrice)
        var previous = (meta.previousClose ?? meta.chartPreviousClose).map { toDecimal($0) }
        var currency = meta.currency ?? "EUR"

        if currency == "GBp" {
            price = price / 100
            previous = previous.map { $0 / 100 }
            currency = "GBP"
        }
        return YahooQuote(price: price, previousClose: previous, currency: currency)
    }

    static func history(symbol: String, range: PriceRange) async throws -> [PricePoint] {
        guard let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw YahooError.badResponse
        }
        let url = "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=\(range.yahooInterval)&range=\(range.yahooRange)"
        let data = try await fetch(url)
        let response = try JSONDecoder().decode(HistoryResponse.self, from: data)
        guard let result = response.chart.result?.first,
              let timestamps = result.timestamp,
              let closes = result.indicators.quote.first?.close else {
            throw YahooError.noData
        }

        let divisor: Double = result.meta.currency == "GBp" ? 100 : 1
        var points: [PricePoint] = []
        for (index, timestamp) in timestamps.enumerated() where index < closes.count {
            if let close = closes[index] {
                points.append(PricePoint(date: Date(timeIntervalSince1970: TimeInterval(timestamp)), close: close / divisor))
            }
        }
        return points
    }

    static func eurRate(for currency: String) async throws -> Decimal {
        if currency == "EUR" { return 1 }
        return try await quote(symbol: "\(currency)EUR=X").price
    }
}
