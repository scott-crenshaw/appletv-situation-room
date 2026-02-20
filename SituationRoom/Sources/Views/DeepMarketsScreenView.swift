import SwiftUI

/// Deep Markets screen.
/// Shows expanded stock watchlist, sector ETF heatmap, and enhanced crypto panel.
struct DeepMarketsScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left column: Stock Watchlist
            VStack(spacing: 12) {
                sectionHeader("WATCHLIST — KEY STOCKS")

                if state.watchlistQuotes.isEmpty {
                    loadingPlaceholder("Fetching Yahoo Finance...")
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 8),
                            GridItem(.flexible(), spacing: 8),
                        ], spacing: 8) {
                            ForEach(state.watchlistQuotes) { quote in
                                StockTile(quote: quote)
                            }
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right column: Sector Heatmap + Crypto
            VStack(spacing: 16) {
                sectionHeader("SECTOR PERFORMANCE")

                if state.sectorQuotes.isEmpty {
                    loadingPlaceholder("Loading sector ETFs...")
                } else {
                    SectorHeatmap(sectors: state.sectorQuotes)
                }

                sectionHeader("CRYPTO MARKETS")

                if state.cryptoPrices.isEmpty {
                    loadingPlaceholder("Fetching CoinGecko...")
                } else {
                    VStack(spacing: 8) {
                        ForEach(state.cryptoPrices) { coin in
                            CryptoDetailRow(coin: coin)
                        }
                    }
                }

                // Fear & Greed
                if let fg = state.fearGreed {
                    sectionHeader("MARKET SENTIMENT")
                    CompactFearGreed(fearGreed: fg)
                }

                Spacer()
            }
            .frame(width: 500)
        }
        .padding(24)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
        }
    }

    private func loadingPlaceholder(_ text: String) -> some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text(text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Stock Tile

struct StockTile: View {
    let quote: MarketQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(quote.displaySymbol)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: quote.isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .font(.system(size: 8))
                    .foregroundColor(quote.isPositive ? .green : .red)
            }

            Text(quote.formattedPrice)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Text(quote.formattedPercent)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(quote.isPositive ? .green : .red)
        }
        .padding(10)
        .background(quote.isPositive ? Color.green.opacity(0.06) : Color.red.opacity(0.06))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(quote.isPositive ? Color.green.opacity(0.15) : Color.red.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Sector Heatmap

struct SectorHeatmap: View {
    let sectors: [MarketQuote]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6),
            GridItem(.flexible(), spacing: 6),
        ], spacing: 6) {
            ForEach(sectors) { sector in
                SectorCell(sector: sector)
            }
        }
    }
}

struct SectorCell: View {
    let sector: MarketQuote

    var body: some View {
        VStack(spacing: 2) {
            Text(sector.displaySymbol)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(sector.formattedPercent)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(sector.isPositive ? .green : .red)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(heatColor.opacity(0.25))
        .cornerRadius(6)
    }

    private var heatColor: Color {
        let pct = sector.changePercent
        if pct > 1.5 { return .green }
        if pct > 0.5 { return .green.opacity(0.6) }
        if pct > 0 { return .green.opacity(0.3) }
        if pct > -0.5 { return .red.opacity(0.3) }
        if pct > -1.5 { return .red.opacity(0.6) }
        return .red
    }
}

// MARK: - Crypto Detail Row

struct CryptoDetailRow: View {
    let coin: CryptoPrice

    var body: some View {
        HStack(spacing: 12) {
            // Coin icon placeholder
            Text(coinEmoji)
                .font(.system(size: 24))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(coin.symbol)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(coin.name)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(formattedPrice)")
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(String(format: "%+.2f%%", coin.priceChangePercentage24h))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(coin.isPositive ? .green : .red)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var coinEmoji: String {
        switch coin.symbol {
        case "BTC": return "₿"
        case "ETH": return "Ξ"
        default: return "◆"
        }
    }

    private var formattedPrice: String {
        if coin.currentPrice >= 1000 {
            return Int(coin.currentPrice).formatted()
        } else if coin.currentPrice >= 1 {
            return String(format: "%.2f", coin.currentPrice)
        } else {
            return String(format: "%.4f", coin.currentPrice)
        }
    }
}

// MARK: - Compact Fear & Greed

struct CompactFearGreed: View {
    let fearGreed: FearGreedIndex

    var body: some View {
        HStack(spacing: 16) {
            // Gauge
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: Double(fearGreed.value) / 100.0)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                Text("\(fearGreed.value)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(gaugeColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(fearGreed.classification.uppercased())
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(gaugeColor)
                Text("Crypto Fear & Greed Index")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var gaugeColor: Color {
        switch fearGreed.value {
        case 0..<25: return .red
        case 25..<45: return .orange
        case 45..<55: return .yellow
        case 55..<75: return .green
        default: return .green
        }
    }
}
