import SwiftUI
import MapKit

/// POC Test #1: MapKit on tvOS with hotspot annotations and auto-panning.
/// This is the primary "situation room" screen — globe + market sidebar.
struct SituationScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 0) {
            // Left: Map (70% width)
            MapPanelView(regionIndex: state.currentMapRegionIndex)
                .frame(maxWidth: .infinity)

            // Right: Sidebar (30% width)
            VStack(spacing: 12) {
                MarketSidebarView(
                    quotes: state.marketQuotes,
                    crypto: state.cryptoPrices,
                    fearGreed: state.fearGreed
                )
            }
            .frame(width: 450)
            .background(Color.white.opacity(0.03))
        }
    }
}

// MARK: - Map Panel with auto-panning

struct MapPanelView: View {
    let regionIndex: Int
    @State private var mapRegion: MKCoordinateRegion

    init(regionIndex: Int) {
        self.regionIndex = regionIndex
        let region = mapRegions[0]
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(latitudeDelta: region.spanLat, longitudeDelta: region.spanLon)
        ))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Map(coordinateRegion: $mapRegion, annotationItems: sampleHotspots) { hotspot in
                MapAnnotation(coordinate: hotspot.coordinate) {
                    HotspotMarker(hotspot: hotspot)
                }
            }
            .mapStyle(.imagery) // Satellite view for situation room feel
            .onChange(of: regionIndex) { _, newIndex in
                let region = mapRegions[newIndex % mapRegions.count]
                withAnimation(.easeInOut(duration: 2.0)) {
                    mapRegion = MKCoordinateRegion(
                        center: region.center,
                        span: MKCoordinateSpan(latitudeDelta: region.spanLat, longitudeDelta: region.spanLon)
                    )
                }
            }

            // Region label overlay
            VStack(alignment: .leading, spacing: 4) {
                Text(mapRegions[regionIndex % mapRegions.count].name.uppercased())
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                // Legend
                HStack(spacing: 16) {
                    legendItem(color: .red, label: "Critical")
                    legendItem(color: .orange, label: "High")
                    legendItem(color: .yellow, label: "Elevated")
                    legendItem(color: .blue, label: "Monitoring")
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
            }
            .padding(16)
            .background(.ultraThinMaterial.opacity(0.8))
            .cornerRadius(8)
            .padding(20)
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - Hotspot Marker

struct HotspotMarker: View {
    let hotspot: Hotspot

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Pulse animation for critical/high
                if hotspot.threatLevel == .critical || hotspot.threatLevel == .high {
                    Circle()
                        .fill(markerColor.opacity(0.3))
                        .frame(width: 24, height: 24)
                        .scaleEffect(pulseScale)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseScale)
                }

                // Core marker
                Circle()
                    .fill(markerColor)
                    .frame(width: markerSize, height: markerSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.6), lineWidth: 1)
                    )

                // Icon overlay
                markerIcon
                    .font(.system(size: markerSize * 0.5))
                    .foregroundColor(.white)
            }

            // Label
            Text(hotspot.name)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2)
                .lineLimit(1)
        }
    }

    private var markerColor: Color {
        switch hotspot.threatLevel {
        case .critical: return .red
        case .high: return .orange
        case .elevated: return .yellow
        case .monitoring: return .blue
        case .low: return .green
        }
    }

    private var markerSize: CGFloat {
        switch hotspot.threatLevel {
        case .critical: return 14
        case .high: return 12
        case .elevated: return 10
        case .monitoring: return 8
        case .low: return 6
        }
    }

    @State private var pulseScale: CGFloat = 1.0

    private var markerIcon: Image {
        switch hotspot.category {
        case .conflict: return Image(systemName: "xmark")
        case .militaryBase: return Image(systemName: "shield.fill")
        case .nuclearSite: return Image(systemName: "bolt.fill")
        case .hotspot: return Image(systemName: "exclamationmark.triangle.fill")
        case .waterway: return Image(systemName: "water.waves")
        }
    }
}

// MARK: - Market Sidebar

struct MarketSidebarView: View {
    let quotes: [MarketQuote]
    let crypto: [CryptoPrice]
    let fearGreed: FearGreedIndex?

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Section: Indices
                sectionHeader("US INDICES")
                ForEach(quotes.filter { $0.symbol.hasPrefix("^") && $0.symbol != "^VIX" }) { quote in
                    MarketRow(symbol: quote.symbol, name: quote.name, price: quote.formattedPrice, change: quote.formattedPercent, isPositive: quote.isPositive)
                }

                // Section: Commodities
                sectionHeader("COMMODITIES")
                ForEach(quotes.filter { !$0.symbol.hasPrefix("^") }) { quote in
                    MarketRow(symbol: quote.symbol, name: quote.name, price: quote.formattedPrice, change: quote.formattedPercent, isPositive: quote.isPositive)
                }

                // VIX
                if let vix = quotes.first(where: { $0.symbol == "^VIX" }) {
                    sectionHeader("VOLATILITY")
                    MarketRow(symbol: "VIX", name: "Fear Index", price: vix.formattedPrice, change: vix.formattedPercent, isPositive: !vix.isPositive) // VIX: down is good
                }

                // Section: Crypto
                sectionHeader("CRYPTO")
                ForEach(crypto) { coin in
                    MarketRow(
                        symbol: coin.symbol,
                        name: coin.name,
                        price: String(format: "$%.0f", coin.currentPrice),
                        change: String(format: "%+.1f%%", coin.priceChangePercentage24h),
                        isPositive: coin.isPositive
                    )
                }

                // Fear & Greed
                if let fg = fearGreed {
                    sectionHeader("MARKET SENTIMENT")
                    HStack {
                        Text("\(fg.value)")
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .foregroundColor(fg.value < 25 ? .red : fg.value < 45 ? .orange : fg.value < 55 ? .yellow : .green)
                        VStack(alignment: .leading) {
                            Text(fg.classification.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("Fear & Greed Index")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(16)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .heavy, design: .monospaced))
            .foregroundColor(.gray)
            .padding(.top, 4)
    }
}

struct MarketRow: View {
    let symbol: String
    let name: String
    let price: String
    let change: String
    let isPositive: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(price)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(change)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
    }
}
