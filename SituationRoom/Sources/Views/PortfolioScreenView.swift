import SwiftUI

/// Energy & Oil Portfolio screen — oil benchmarks with 30-day charts,
/// energy portfolio (13 stocks), and high-oil portfolio (5 stocks).
/// Single screen, no scrolling, information-dense with sparklines.
struct PortfolioScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        VStack(spacing: 12) {
            // Top: Oil Benchmarks with 30-day charts
            oilBenchmarksRow

            // Bottom: Two portfolios side by side
            HStack(spacing: 16) {
                // Left: Energy Portfolio (13 stocks)
                energyPortfolioPanel
                    .frame(maxWidth: .infinity)

                // Right: High Oil Portfolio (5 stocks)
                highOilPortfolioPanel
                    .frame(width: 520)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    // MARK: - Oil Benchmarks Row

    private var oilBenchmarksRow: some View {
        VStack(spacing: 6) {
            HStack {
                Text("OIL BENCHMARKS")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text("30-DAY TREND")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray.opacity(0.6))
            }

            HStack(spacing: 12) {
                // WTI
                if let wti = state.oilBenchmarks.first(where: { $0.symbol == "CL=F" }) {
                    OilBenchmarkCard(
                        label: "WTI CRUDE",
                        quote: wti,
                        sparkline: state.portfolioSparklines["CL=F"]
                    )
                }

                // Brent
                if let brent = state.oilBenchmarks.first(where: { $0.symbol == "BZ=F" }) {
                    OilBenchmarkCard(
                        label: "BRENT CRUDE",
                        quote: brent,
                        sparkline: state.portfolioSparklines["BZ=F"]
                    )
                }

                // Brent-WTI Spread
                spreadCard
            }
        }
    }

    private var spreadCard: some View {
        let wtiPrice = state.oilBenchmarks.first(where: { $0.symbol == "CL=F" })?.price ?? 0
        let brentPrice = state.oilBenchmarks.first(where: { $0.symbol == "BZ=F" })?.price ?? 0
        let spread = brentPrice - wtiPrice

        // Compute spread sparkline from the two benchmark histories
        let wtiHistory = state.portfolioSparklines["CL=F"] ?? []
        let brentHistory = state.portfolioSparklines["BZ=F"] ?? []
        let spreadHistory: [Double] = {
            let count = min(wtiHistory.count, brentHistory.count)
            guard count >= 2 else { return [] }
            return (0..<count).map { brentHistory[$0] - wtiHistory[$0] }
        }()

        return VStack(alignment: .leading, spacing: 4) {
            Text("BRENT-WTI SPREAD")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text(String(format: "$%.2f", spread))
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(spread > 0 ? .cyan : .orange)
            if !spreadHistory.isEmpty {
                AreaSparkline(prices: spreadHistory, color: .cyan)
                    .frame(maxHeight: .infinity)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyan.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Energy Portfolio Panel

    private var energyPortfolioPanel: some View {
        VStack(spacing: 6) {
            HStack {
                Text("ENERGY PORTFOLIO")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                portfolioStats(state.energyPortfolio)
            }

            // 7-column grid, 2 rows
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(state.energyPortfolio) { quote in
                    PortfolioCell(
                        quote: quote,
                        sparkline: state.portfolioSparklines[quote.symbol]
                    )
                }
            }
        }
    }

    // MARK: - High Oil Portfolio Panel

    private var highOilPortfolioPanel: some View {
        VStack(spacing: 6) {
            HStack {
                Text("HIGH OIL PORTFOLIO")
                    .font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                portfolioStats(state.highOilPortfolio)
            }

            // Single column list — more room for charts since only 5 stocks
            VStack(spacing: 6) {
                ForEach(state.highOilPortfolio) { quote in
                    HighOilStockRow(
                        quote: quote,
                        sparkline: state.portfolioSparklines[quote.symbol]
                    )
                }
            }
        }
    }

    // MARK: - Portfolio Stats Summary

    private func portfolioStats(_ quotes: [MarketQuote]) -> some View {
        let avgChange = quotes.isEmpty ? 0 : quotes.map(\.changePercent).reduce(0, +) / Double(quotes.count)
        let gainers = quotes.filter(\.isPositive).count
        let losers = quotes.count - gainers

        return HStack(spacing: 12) {
            Text("AVG: \(String(format: "%+.1f%%", avgChange))")
                .foregroundColor(avgChange >= 0 ? .green : .red)
            Text("\(gainers)▲")
                .foregroundColor(.green)
            Text("\(losers)▼")
                .foregroundColor(.red)
        }
        .font(.system(size: 12, weight: .bold, design: .monospaced))
    }
}

// MARK: - Oil Benchmark Card (large price + 30-day area chart)

struct OilBenchmarkCard: View {
    let label: String
    let quote: MarketQuote
    let sparkline: [Double]?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(quote.formattedPrice)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(quote.formattedPercent)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(quote.isPositive ? .green : .red)
            }

            if let prices = sparkline, prices.count >= 2 {
                AreaSparkline(prices: prices, color: quote.isPositive ? .green : .red)
                    .frame(maxHeight: .infinity)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke((quote.isPositive ? Color.green : Color.red).opacity(0.15), lineWidth: 0.5)
        )
    }
}

// MARK: - Portfolio Cell (compact stock tile with sparkline)

struct PortfolioCell: View {
    let quote: MarketQuote
    let sparkline: [Double]?

    var body: some View {
        VStack(spacing: 3) {
            // Symbol
            Text(quote.displaySymbol)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            // Price
            Text(quote.formattedPrice)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            // Change %
            Text(quote.formattedPercent)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(quote.isPositive ? .green : .red)

            // Sparkline (30-day)
            if let prices = sparkline, prices.count >= 2 {
                AreaSparkline(prices: prices, color: quote.isPositive ? .green : .red)
                    .frame(height: 28)
            } else {
                Spacer().frame(height: 28)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .background(quote.isPositive ? Color.green.opacity(0.05) : Color.red.opacity(0.05))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke((quote.isPositive ? Color.green : Color.red).opacity(0.12), lineWidth: 0.5)
        )
    }
}

// MARK: - High Oil Stock Row (wider format with prominent chart)

struct HighOilStockRow: View {
    let quote: MarketQuote
    let sparkline: [Double]?

    var body: some View {
        HStack(spacing: 10) {
            // Symbol + price
            VStack(alignment: .leading, spacing: 2) {
                Text(quote.displaySymbol)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(quote.formattedPrice)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(quote.formattedPercent)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(quote.isPositive ? .green : .red)
            }
            .frame(width: 100, alignment: .leading)

            // 30-day sparkline
            if let prices = sparkline, prices.count >= 2 {
                AreaSparkline(prices: prices, color: quote.isPositive ? .green : .red)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer()
            }
        }
        .padding(8)
        .background(quote.isPositive ? Color.green.opacity(0.04) : Color.red.opacity(0.04))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke((quote.isPositive ? Color.green : Color.red).opacity(0.12), lineWidth: 0.5)
        )
    }
}

// MARK: - Area Sparkline (filled area chart for 30-day trends)

struct AreaSparkline: View {
    let prices: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geo in
            let minP = prices.min() ?? 0
            let maxP = prices.max() ?? 1
            let range = max(maxP - minP, 0.01)

            // Line path
            let linePath = Path { path in
                for (i, price) in prices.enumerated() {
                    let x = geo.size.width * CGFloat(i) / CGFloat(prices.count - 1)
                    let y = geo.size.height * (1 - CGFloat((price - minP) / range))
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }

            // Fill path (area under the line)
            let fillPath = Path { path in
                for (i, price) in prices.enumerated() {
                    let x = geo.size.width * CGFloat(i) / CGFloat(prices.count - 1)
                    let y = geo.size.height * (1 - CGFloat((price - minP) / range))
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                path.closeSubpath()
            }

            fillPath.fill(
                LinearGradient(
                    colors: [color.opacity(0.25), color.opacity(0.02)],
                    startPoint: .top, endPoint: .bottom
                )
            )

            linePath.stroke(color.opacity(0.8), lineWidth: 1.5)
        }
    }
}
