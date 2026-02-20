import Foundation

struct MarketQuote: Identifiable, Codable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let price: Double
    let change: Double
    let changePercent: Double

    var isPositive: Bool { change >= 0 }

    /// Short ticker symbol for the market strip
    var displaySymbol: String {
        switch symbol {
        case "^GSPC": return "S&P"
        case "^DJI": return "DOW"
        case "^IXIC": return "NASDAQ"
        case "^VIX": return "VIX"
        case "GC=F": return "GOLD"
        case "CL=F": return "OIL"
        // Sector ETFs
        case "XLK": return "TECH"
        case "XLF": return "FINANC"
        case "XLV": return "HEALTH"
        case "XLE": return "ENERGY"
        case "XLY": return "DISCR"
        case "XLP": return "STAPLE"
        case "XLI": return "INDUST"
        case "XLB": return "MATER"
        case "XLRE": return "REAL-E"
        case "XLU": return "UTIL"
        case "XLC": return "COMMS"
        case "SMH": return "SEMI"
        default: return symbol
        }
    }

    var formattedPrice: String {
        if price > 1000 {
            return String(format: "%.2f", price)
        } else if price > 1 {
            return String(format: "%.2f", price)
        } else {
            return String(format: "%.4f", price)
        }
    }
    var formattedChange: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change))"
    }
    var formattedPercent: String {
        let sign = isPositive ? "+" : ""
        return "\(sign)\(String(format: "%.2f", changePercent))%"
    }
}

struct CryptoPrice: Identifiable, Codable {
    var id: String { coinId }
    let coinId: String
    let symbol: String
    let name: String
    let currentPrice: Double
    let priceChangePercentage24h: Double

    var isPositive: Bool { priceChangePercentage24h >= 0 }
}

/// Yahoo Finance quote response (used by World Monitor's macro-signals)
struct YahooQuoteResponse: Codable {
    let quoteResponse: YahooQuoteResult?

    struct YahooQuoteResult: Codable {
        let result: [YahooQuote]?
    }

    struct YahooQuote: Codable {
        let symbol: String?
        let shortName: String?
        let regularMarketPrice: Double?
        let regularMarketChange: Double?
        let regularMarketChangePercent: Double?
    }
}

/// CoinGecko simple price response
struct CoinGeckoResponse: Codable {
    // Dynamic keys (bitcoin, ethereum, solana)
    // Handled via manual decoding
}

/// Fear & Greed index from alternative.me
struct FearGreedResponse: Codable {
    let data: [FearGreedEntry]?

    struct FearGreedEntry: Codable {
        let value: String?
        let valueClassification: String?
        let timestamp: String?

        enum CodingKeys: String, CodingKey {
            case value
            case valueClassification = "value_classification"
            case timestamp
        }
    }
}

struct FearGreedIndex {
    let value: Int
    let classification: String // "Extreme Fear", "Fear", "Neutral", "Greed", "Extreme Greed"

    var color: String {
        switch value {
        case 0..<25: return "red"
        case 25..<45: return "orange"
        case 45..<55: return "yellow"
        case 55..<75: return "green"
        default: return "green"
        }
    }
}
