import SwiftUI
import MapKit

/// Screen 1: Global Situation — world map with hotspot annotations, auto-panning, and market sidebar.
struct SituationScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 0) {
            // Left: Map (75% width)
            MapPanelView(regionIndex: state.currentMapRegionIndex, earthquakes: state.earthquakes)
                .frame(maxWidth: .infinity)

            // Right: Threat summary sidebar
            ThreatSummarySidebar(state: state)
                .frame(width: 420)
                .background(Color.white.opacity(0.03))
        }
    }
}

// MARK: - Map Panel with auto-panning

struct MapPanelView: View {
    let regionIndex: Int
    let earthquakes: [Earthquake]
    @State private var mapRegion: MKCoordinateRegion

    init(regionIndex: Int, earthquakes: [Earthquake] = []) {
        self.regionIndex = regionIndex
        self.earthquakes = earthquakes
        let region = mapRegions[0]
        _mapRegion = State(initialValue: MKCoordinateRegion(
            center: region.center,
            span: MKCoordinateSpan(latitudeDelta: region.spanLat, longitudeDelta: region.spanLon)
        ))
    }

    private var allAnnotations: [MapAnnotationItem] {
        let hotspotItems = sampleHotspots.map { MapAnnotationItem.hotspot($0) }
        let quakeItems = earthquakes.prefix(10).map { MapAnnotationItem.earthquake($0) }
        return hotspotItems + quakeItems
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Map(coordinateRegion: $mapRegion, annotationItems: allAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    switch item {
                    case .hotspot(let h):
                        HotspotMarker(hotspot: h)
                    case .earthquake(let q):
                        EarthquakeRingMarker(earthquake: q)
                    }
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

// MARK: - Threat Summary Sidebar (replaces market sidebar — markets are on the ticker + dedicated screen)

struct ThreatSummarySidebar: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // DEFCON
                HStack(spacing: 12) {
                    Text("DEFCON \(state.defconLevel)")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(defconColor)
                    Spacer()
                    if let vix = state.marketQuotes.first(where: { $0.symbol == "^VIX" }) {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("VIX")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                            Text(vix.formattedPrice)
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(vix.price > 25 ? .red : .yellow)
                        }
                    }
                    if let fg = state.fearGreed {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("F&G")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.gray)
                            Text("\(fg.value)")
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(fg.value < 25 ? .red : fg.value < 45 ? .orange : .green)
                        }
                    }
                }
                .padding(12)
                .background(defconColor.opacity(0.1))
                .cornerRadius(8)

                // Recent Earthquakes
                sectionHeader("RECENT EARTHQUAKES (\(state.earthquakes.count))")
                ForEach(state.earthquakes.prefix(6)) { quake in
                    HStack(spacing: 8) {
                        Text(quake.formattedMagnitude)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: 40)
                            .padding(.vertical, 3)
                            .background(quakeMagColor(quake.magnitude).opacity(0.8))
                            .cornerRadius(4)
                        Text(quake.place)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                        Spacer()
                    }
                }

                // Natural Events
                if !state.naturalEvents.isEmpty {
                    sectionHeader("NATURAL EVENTS (\(state.naturalEvents.count))")
                    ForEach(state.naturalEvents.prefix(5)) { event in
                        HStack(spacing: 8) {
                            Image(systemName: event.categoryIcon)
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                                .frame(width: 20)
                            Text(event.title)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                            Spacer()
                        }
                    }
                }

                // Top Headlines
                sectionHeader("THREAT FEEDS")
                ForEach(state.headlines.prefix(8)) { item in
                    HStack(spacing: 6) {
                        Text("■")
                            .font(.system(size: 6))
                            .foregroundColor(.red)
                        Text(item.source.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        Text(item.title)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
        }
    }

    private var defconColor: Color {
        switch state.defconLevel {
        case 1, 2: return .red
        case 3: return .orange
        case 4: return .yellow
        default: return .green
        }
    }

    private func quakeMagColor(_ mag: Double) -> Color {
        mag >= 6 ? .red : mag >= 5 ? .orange : .yellow
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .heavy, design: .monospaced))
            .foregroundColor(.gray)
            .padding(.top, 4)
    }
}

// MARK: - Map Annotation Item (unified enum for hotspots + earthquakes)

enum MapAnnotationItem: Identifiable {
    case hotspot(Hotspot)
    case earthquake(Earthquake)

    var id: String {
        switch self {
        case .hotspot(let h): return "hotspot-\(h.id)"
        case .earthquake(let q): return "quake-\(q.id)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .hotspot(let h): return h.coordinate
        case .earthquake(let q): return CLLocationCoordinate2D(latitude: q.latitude, longitude: q.longitude)
        }
    }
}

// MARK: - Earthquake Ring Marker (expanding concentric rings on map)

struct EarthquakeRingMarker: View {
    let earthquake: Earthquake
    @State private var ringScale: CGFloat = 0.5

    private var ringSize: CGFloat {
        CGFloat(earthquake.magnitude) * 4 // Scale ring by magnitude
    }

    private var depthColor: Color {
        // Red = shallow (dangerous), blue = deep
        switch earthquake.depth {
        case ..<30: return .red
        case ..<100: return .orange
        case ..<300: return .yellow
        default: return .blue
        }
    }

    private var ageOpacity: Double {
        let hours = Date().timeIntervalSince(earthquake.time) / 3600
        return max(0.3, 1.0 - (hours / 24.0))
    }

    var body: some View {
        ZStack {
            // Outer expanding ring
            Circle()
                .stroke(depthColor.opacity(0.3 * ageOpacity), lineWidth: 1.5)
                .frame(width: ringSize * 2.5, height: ringSize * 2.5)
                .scaleEffect(ringScale)

            // Middle ring
            Circle()
                .stroke(depthColor.opacity(0.5 * ageOpacity), lineWidth: 1.5)
                .frame(width: ringSize * 1.5, height: ringSize * 1.5)
                .scaleEffect(ringScale)

            // Core dot
            Circle()
                .fill(depthColor.opacity(ageOpacity))
                .frame(width: ringSize * 0.6, height: ringSize * 0.6)

            // Magnitude label
            Text(earthquake.formattedMagnitude)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 2)
                .offset(y: ringSize * 1.5)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                ringScale = 1.2
            }
        }
    }
}
