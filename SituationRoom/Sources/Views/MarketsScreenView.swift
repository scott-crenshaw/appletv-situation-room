import SwiftUI

/// Markets & Economy screen — large format financial data.
struct MarketsScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left column: Market indices + commodities
            VStack(spacing: 16) {
                // Major indices — big cards
                sectionHeader("US MARKET INDICES")
                HStack(spacing: 12) {
                    ForEach(state.marketQuotes.filter { ["^GSPC", "^DJI", "^IXIC"].contains($0.symbol) }) { quote in
                        LargeMarketCard(quote: quote)
                    }
                }

                // Commodities
                sectionHeader("COMMODITIES")
                HStack(spacing: 12) {
                    ForEach(state.marketQuotes.filter { !$0.symbol.hasPrefix("^") }) { quote in
                        LargeMarketCard(quote: quote)
                    }
                }

                // Stock heatmap
                if !state.watchlistQuotes.isEmpty {
                    sectionHeader("S&P 500 HEATMAP")
                    StockHeatmapView(quotes: state.watchlistQuotes)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right column: Crypto + Sentiment
            VStack(spacing: 16) {
                sectionHeader("CRYPTO")
                ForEach(state.cryptoPrices) { coin in
                    CryptoCard(coin: coin)
                }

                // Fear & Greed gauge
                if let fg = state.fearGreed {
                    sectionHeader("MARKET SENTIMENT")
                    FearGreedGauge(index: fg)
                }

                // VIX
                if let vix = state.marketQuotes.first(where: { $0.symbol == "^VIX" }) {
                    sectionHeader("VOLATILITY INDEX")
                    VIXCard(vix: vix)
                }

                Spacer()
            }
            .frame(width: 400)
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
}

// MARK: - Large Market Card

struct LargeMarketCard: View {
    let quote: MarketQuote

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(quote.name)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(1)

            Text(quote.formattedPrice)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.8), value: quote.formattedPrice)

            HStack(spacing: 8) {
                Image(systemName: quote.isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                    .foregroundColor(quote.isPositive ? .green : .red)
                    .font(.system(size: 16))

                Text(quote.formattedChange)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(quote.isPositive ? .green : .red)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.8), value: quote.formattedChange)

                Text(quote.formattedPercent)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(quote.isPositive ? .green : .red)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.8), value: quote.formattedPercent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Crypto Card

struct CryptoCard: View {
    let coin: CryptoPrice

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(coin.symbol)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(coin.name)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.gray)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(Int(coin.currentPrice).formatted())")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.8), value: coin.currentPrice)
                Text(String(format: "%+.1f%%", coin.priceChangePercentage24h))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(coin.isPositive ? .green : .red)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.8), value: coin.priceChangePercentage24h)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Fear & Greed Gauge

struct FearGreedGauge: View {
    let index: FearGreedIndex

    private var gaugeColor: Color {
        switch index.value {
        case 0..<25: return .red
        case 25..<45: return .orange
        case 45..<55: return .yellow
        case 55..<75: return .green
        default: return .green
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background arc
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 120, height: 120)

                // Value arc
                Circle()
                    .trim(from: 0, to: CGFloat(index.value) / 100.0)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(index.value)")
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(gaugeColor)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.8), value: index.value)
                    Text(index.classification.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - VIX Card

struct VIXCard: View {
    let vix: MarketQuote

    var body: some View {
        HStack {
            Text("VIX")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Spacer()
            Text(vix.formattedPrice)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(Double(vix.formattedPrice) ?? 0 > 25 ? .red : .yellow)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.8), value: vix.formattedPrice)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Stock Heatmap

struct StockHeatmapView: View {
    let quotes: [MarketQuote]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
            ForEach(quotes) { quote in
                HeatmapCell(quote: quote)
            }
        }
    }
}

struct HeatmapCell: View {
    let quote: MarketQuote

    private var cellColor: Color {
        let pct = quote.changePercent
        if pct > 3 { return Color(red: 0, green: 0.7, blue: 0) }
        if pct > 1.5 { return Color(red: 0, green: 0.5, blue: 0) }
        if pct > 0.5 { return Color(red: 0, green: 0.35, blue: 0) }
        if pct > 0 { return Color(red: 0, green: 0.2, blue: 0) }
        if pct > -0.5 { return Color(red: 0.2, green: 0, blue: 0) }
        if pct > -1.5 { return Color(red: 0.35, green: 0, blue: 0) }
        if pct > -3 { return Color(red: 0.5, green: 0, blue: 0) }
        return Color(red: 0.7, green: 0, blue: 0)
    }

    var body: some View {
        VStack(spacing: 1) {
            Text(quote.displaySymbol)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .lineLimit(1)
            Text(quote.formattedPercent)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.8), value: quote.formattedPercent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(cellColor)
        .cornerRadius(3)
    }
}
