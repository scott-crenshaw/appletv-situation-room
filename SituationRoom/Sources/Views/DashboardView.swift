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
                        case .portfolio:
                            PortfolioScreenView(state: state)
                        case .threats:
                            ThreatScreenView(state: state)
                        case .space:
                            SpaceScreenView(state: state)
                        case .cyber:
                            CyberScreenView(state: state)
                        case .airTraffic:
                            AirTrafficScreenView(state: state)
                        case .gulfCommand:
                            GulfCommandScreenView(state: state)
                        case .fireWatch:
                            FireWatchScreenView(state: state)
                        case .digitalInfra:
                            DigitalInfraScreenView(state: state)
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
        .overlay(CRTOverlay())
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
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Spacer()

            // Countdown timers
            CountdownTimersView(state: state)

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
    @State private var contentWidth: CGFloat = 0
    @State private var scrollStartDate: Date = .now

    private let scrollSpeed: CGFloat = 70

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                tickerContent
                    .offset(x: computeOffset(at: timeline.date, containerWidth: geo.size.width))
            }
        }
        .frame(height: 40)
        .background(Color.white.opacity(0.03))
        .clipped()
        .onChange(of: headlines.count) {
            scrollStartDate = .now
        }
    }

    private func computeOffset(at date: Date, containerWidth: CGFloat) -> CGFloat {
        guard contentWidth > 0, containerWidth > 0 else { return containerWidth }
        let totalDistance = containerWidth + contentWidth
        let elapsed = CGFloat(date.timeIntervalSince(scrollStartDate))
        let traveled = elapsed * scrollSpeed
        let cycleTraveled = traveled.truncatingRemainder(dividingBy: totalDistance)
        return containerWidth - cycleTraveled
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
                Color.clear
                    .onAppear { contentWidth = contentGeo.size.width }
                    .onChange(of: headlines.count) { contentWidth = contentGeo.size.width }
            }
        )
    }
}

// MARK: - Countdown Timers

struct CountdownTimersView: View {
    @ObservedObject var state: DashboardState
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 16) {
            // Market hours
            Text(marketStatus)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.8))

            // Data refresh countdown
            Text(refreshCountdown)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.green.opacity(0.6))

            // Next screen countdown
            if state.isAutoRotating {
                Text(screenCountdown)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.orange.opacity(0.6))
            }
        }
        .onReceive(timer) { now = $0 }
    }

    private var marketStatus: String {
        let cal = Calendar(identifier: .gregorian)
        var utcCal = cal
        utcCal.timeZone = TimeZone(identifier: "America/New_York")!

        let comps = utcCal.dateComponents([.hour, .minute, .weekday], from: now)
        guard let hour = comps.hour, let minute = comps.minute, let weekday = comps.weekday else {
            return "NYSE --:--"
        }

        let totalMin = hour * 60 + minute
        let openMin = 9 * 60 + 30  // 9:30 ET
        let closeMin = 16 * 60     // 16:00 ET
        let isWeekday = weekday >= 2 && weekday <= 6

        if isWeekday && totalMin >= openMin && totalMin < closeMin {
            let remaining = closeMin - totalMin
            return "NYSE CLOSES \(remaining / 60)h \(remaining % 60)m"
        } else if isWeekday && totalMin < openMin {
            let until = openMin - totalMin
            return "NYSE OPEN \(until / 60)h \(until % 60)m"
        } else {
            return "NYSE CLOSED"
        }
    }

    private var refreshCountdown: String {
        let elapsed = now.timeIntervalSince(state.lastUpdated)
        let remaining = max(0, Int(state.dataRefreshInterval - elapsed))
        return "REFRESH \(remaining)s"
    }

    private var screenCountdown: String {
        let elapsed = now.timeIntervalSince(state.lastUpdated)
        let cycleElapsed = elapsed.truncatingRemainder(dividingBy: state.autoRotateInterval)
        let remaining = max(0, Int(state.autoRotateInterval - cycleElapsed))
        return "NEXT \(remaining)s"
    }
}

// MARK: - CRT Scan Line Overlay

struct CRTOverlay: View {
    @State private var sweepOffset: CGFloat = -1.0

    var body: some View {
        ZStack {
            // Horizontal scan lines
            Canvas { context, size in
                for y in stride(from: 0, to: size.height, by: 3) {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(0.03)))
                }
            }

            // Slow vertical gradient sweep
            GeometryReader { geo in
                LinearGradient(
                    colors: [.clear, .white.opacity(0.015), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                .offset(y: sweepOffset * geo.size.height)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                sweepOffset = 1.0
            }
        }
    }
}
