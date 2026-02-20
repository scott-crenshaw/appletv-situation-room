import SwiftUI

/// Main dashboard view that auto-rotates between screens.
/// Designed for tvOS: large text, high contrast, focus-engine friendly.
struct DashboardView: View {
    @StateObject private var state = DashboardState()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if state.isLoading {
                loadingView
            } else {
                VStack(spacing: 0) {
                    // Top status bar
                    StatusBarView(state: state)

                    // Main content area — switches based on current screen
                    Group {
                        switch state.currentScreen {
                        case .situation:
                            SituationScreenView(state: state)
                        case .liveIntel:
                            LiveIntelScreenView(state: state)
                        case .markets:
                            MarketsScreenView(state: state)
                        case .threats:
                            ThreatScreenView(state: state)
                        case .space:
                            SpaceScreenView(state: state)
                        case .cyber:
                            CyberScreenView(state: state)
                        case .deepMarkets:
                            DeepMarketsScreenView(state: state)
                        case .globalThreats:
                            GlobalThreatMatrixView(state: state)
                        }
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 1.0)))
                    .id(state.currentScreen)

                    // Bottom dual ticker: markets on top, news below
                    TickerBarView(
                        marketQuotes: state.marketQuotes,
                        cryptoPrices: state.cryptoPrices,
                        headlines: state.headlines
                    )
                }
            }
        }
        .focusable()
        .onAppear { state.startDashboard() }
        .onDisappear { state.stopDashboard() }
        .onMoveCommand { direction in
            switch direction {
            case .right: state.navigateForward()
            case .left: state.navigateBack()
            default: break
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)
            Text("INITIALIZING SITUATION ROOM")
                .font(.system(size: 28, weight: .light, design: .monospaced))
                .foregroundColor(.green.opacity(0.8))
            Text("Connecting to data sources...")
                .font(.system(size: 18, weight: .light, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Status Bar (top of every screen)

struct StatusBarView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack {
            // DEFCON indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(defconColor)
                    .frame(width: 12, height: 12)
                Text("DEFCON \(state.defconLevel)")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(defconColor)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(defconColor.opacity(0.15))
            .cornerRadius(8)

            Spacer()

            // Current screen label
            Text(state.currentScreen.rawValue)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Spacer()

            // Time (UTC)
            Text(utcTimeString)
                .font(.system(size: 20, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)

            // Auto-rotate indicator
            Image(systemName: state.isAutoRotating ? "arrow.triangle.2.circlepath" : "pause.circle")
                .foregroundColor(state.isAutoRotating ? .green.opacity(0.6) : .orange.opacity(0.6))
                .font(.system(size: 18))
                .padding(.leading, 8)
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }

    private var defconColor: Color {
        switch state.defconLevel {
        case 1: return .red
        case 2: return .red
        case 3: return .orange
        case 4: return .yellow
        case 5: return .green
        default: return .gray
        }
    }

    private var utcTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: Date()) + " UTC"
    }
}

// MARK: - Dual Ticker Bar (market strip + news ticker)

struct TickerBarView: View {
    let marketQuotes: [MarketQuote]
    let cryptoPrices: [CryptoPrice]
    let headlines: [NewsItem]

    var body: some View {
        VStack(spacing: 0) {
            // Top row: Market data
            MarketTickerRow(marketQuotes: marketQuotes, cryptoPrices: cryptoPrices)

            // Thin divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)

            // Bottom row: News headlines
            NewsTickerRow(headlines: headlines)
        }
    }
}

// MARK: - Market Ticker Row

struct MarketTickerRow: View {
    let marketQuotes: [MarketQuote]
    let cryptoPrices: [CryptoPrice]
    @State private var offset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private let scrollSpeed: CGFloat = 50 // Slower than news — markets are glanceable

    var body: some View {
        GeometryReader { geo in
            tickerContent
                .offset(x: offset)
                .onAppear {
                    containerWidth = geo.size.width
                    startScrolling()
                }
                .onChange(of: marketQuotes.count) {
                    offset = 0
                    startScrolling()
                }
        }
        .frame(height: 36)
        .background(Color.white.opacity(0.03))
        .clipped()
    }

    private var tickerContent: some View {
        HStack(spacing: 0) {
            // Market indices and commodities
            ForEach(marketQuotes) { quote in
                marketQuoteItem(symbol: quote.displaySymbol, price: quote.formattedPrice, change: quote.formattedPercent, isPositive: quote.isPositive)
            }
            // Crypto
            ForEach(cryptoPrices) { coin in
                marketQuoteItem(symbol: coin.symbol, price: "$\(Int(coin.currentPrice).formatted())", change: String(format: "%+.1f%%", coin.priceChangePercentage24h), isPositive: coin.isPositive)
            }
        }
        .fixedSize()
        .background(
            GeometryReader { contentGeo in
                Color.clear.onAppear {
                    contentWidth = contentGeo.size.width
                }
            }
        )
    }

    private func marketQuoteItem(symbol: String, price: String, change: String, isPositive: Bool) -> some View {
        HStack(spacing: 6) {
            Text(symbol)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text(price)
                .font(.system(size: 18, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
            Text(change)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(isPositive ? .green : .red)
            Image(systemName: isPositive ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                .font(.system(size: 10))
                .foregroundColor(isPositive ? .green : .red)
        }
        .fixedSize()
        .padding(.trailing, 40)
    }

    private func startScrolling() {
        guard contentWidth > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startScrolling() }
            return
        }
        let totalDistance = containerWidth + contentWidth
        let duration = Double(totalDistance) / Double(scrollSpeed)
        offset = containerWidth
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = -contentWidth
        }
    }
}

// MARK: - News Ticker Row

struct NewsTickerRow: View {
    let headlines: [NewsItem]
    @State private var offset: CGFloat = 0
    @State private var contentWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0

    private let scrollSpeed: CGFloat = 70

    var body: some View {
        GeometryReader { geo in
            tickerContent
                .offset(x: offset)
                .onAppear {
                    containerWidth = geo.size.width
                    startScrolling()
                }
                .onChange(of: headlines.count) {
                    offset = 0
                    startScrolling()
                }
        }
        .frame(height: 40)
        .background(Color.white.opacity(0.03))
        .clipped()
    }

    private var tickerContent: some View {
        HStack(spacing: 0) {
            ForEach(headlines) { item in
                HStack(spacing: 10) {
                    Text("■")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                    Text(item.source.uppercased())
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                    Text(item.title)
                        .font(.system(size: 20, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                .fixedSize()
                .padding(.trailing, 60)
            }
        }
        .fixedSize()
        .background(
            GeometryReader { contentGeo in
                Color.clear.onAppear {
                    contentWidth = contentGeo.size.width
                }
                .id(headlines.count)
            }
        )
    }

    private func startScrolling() {
        guard contentWidth > 0 else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { startScrolling() }
            return
        }
        let totalDistance = containerWidth + contentWidth
        let duration = Double(totalDistance) / Double(scrollSpeed)
        offset = containerWidth
        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            offset = -contentWidth
        }
    }
}
