import SwiftUI
import MapKit

/// Screen 10: Global Fire Watch — NASA FIRMS thermal hotspot detection.
/// Pulsing ember-glow dots on a dark satellite map + fire intel panel.
struct FireWatchScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left: Fire map (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    "THERMAL ANOMALY DETECTION",
                    subtitle: "\(state.fireHotspots.count) HOTSPOTS — NASA VIIRS 24H"
                )
                FireMapView(hotspots: state.fireHotspots)
                    .frame(maxHeight: .infinity)
                FireStatsBar(hotspots: state.fireHotspots)
            }
            .frame(maxWidth: .infinity)

            // Right: Fire intel panel (1/3 width)
            VStack(spacing: 12) {
                sectionHeader("FIRE INTEL", subtitle: nil)
                RegionBreakdown(hotspots: state.fireHotspots)
                sectionHeader("HIGHEST INTENSITY", subtitle: nil)
                TopFiresList(hotspots: state.fireHotspots)
                    .frame(maxHeight: .infinity)
                ConfidenceLegend()
            }
            .frame(width: 540)
        }
        .padding(24)
    }

    private func sectionHeader(_ title: String, subtitle: String?) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundColor(.gray)
            if let subtitle {
                Spacer()
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.orange.opacity(0.8))
            }
            Spacer()
        }
    }
}

// MARK: - Fire Map (MapKit with ember-glow hotspot annotations)

struct FireMapView: View {
    let hotspots: [FireHotspot]

    @State private var cameraPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        distance: 40_000_000
    ))

    /// Sample hotspots to stay under the 500-annotation GPU limit
    private var displayHotspots: [FireHotspot] {
        if hotspots.count <= 500 {
            return hotspots
        }
        // Keep all high-confidence, sample the rest
        let high = hotspots.filter { $0.confidence == .high }
        let remaining = hotspots.filter { $0.confidence != .high }
        let sampleCount = max(0, 500 - high.count)
        let sampled = Array(remaining.prefix(sampleCount))
        return high + sampled
    }

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            ForEach(displayHotspots) { hotspot in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: hotspot.latitude,
                    longitude: hotspot.longitude
                ), anchor: .center) {
                    EmberDot(hotspot: hotspot)
                }
            }
        }
        .mapStyle(.imagery(elevation: .flat))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Ember Glow Dot (pulsing fire annotation)

struct EmberDot: View {
    let hotspot: FireHotspot
    @State private var isPulsing = false

    private var baseColor: Color {
        switch hotspot.confidence {
        case .high: return .red
        case .nominal: return .orange
        case .low: return .yellow
        }
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(baseColor.opacity(isPulsing ? 0.15 : 0.08))
                .frame(width: hotspot.dotSize * 3, height: hotspot.dotSize * 3)

            // Inner ember
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.9),
                            baseColor,
                            baseColor.opacity(0.3)
                        ]),
                        center: .center,
                        startRadius: 0,
                        endRadius: hotspot.dotSize * 0.7
                    )
                )
                .frame(width: hotspot.dotSize, height: hotspot.dotSize)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: Double.random(in: 1.5...3.0)).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Region Breakdown Panel

struct RegionBreakdown: View {
    let hotspots: [FireHotspot]

    private var regionCounts: [(String, Int)] {
        var counts: [String: Int] = [:]
        for h in hotspots {
            counts[h.region, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(spacing: 6) {
            ForEach(regionCounts, id: \.0) { region, count in
                HStack {
                    Text(region.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()

                    // Bar
                    let maxCount = regionCounts.first?.1 ?? 1
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(barColor(for: count))
                            .frame(width: geo.size.width * CGFloat(count) / CGFloat(maxCount))
                    }
                    .frame(width: 200, height: 12)

                    Text("\(count)")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(.orange)
                        .frame(width: 60, alignment: .trailing)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private func barColor(for count: Int) -> Color {
        let maxCount = regionCounts.first?.1 ?? 1
        let ratio = Double(count) / Double(maxCount)
        if ratio > 0.7 { return .red.opacity(0.8) }
        if ratio > 0.3 { return .orange.opacity(0.8) }
        return .yellow.opacity(0.6)
    }
}

// MARK: - Top Fires List (highest FRP)

struct TopFiresList: View {
    let hotspots: [FireHotspot]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(hotspots.prefix(15)) { hotspot in
                    HStack(spacing: 12) {
                        // Intensity indicator
                        Circle()
                            .fill(intensityColor(frp: hotspot.frp))
                            .frame(width: 10, height: 10)

                        // Location
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(format: "%.3f°, %.3f°", hotspot.latitude, hotspot.longitude))
                                .font(.system(size: 13, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                            Text("\(hotspot.region) — \(hotspot.formattedTime)")
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        // FRP
                        Text(hotspot.formattedFRP)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)

                        // Confidence badge
                        Text(hotspot.confidence.rawValue.prefix(1).uppercased())
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(width: 20, height: 20)
                            .background(confidenceColor(hotspot.confidence))
                            .cornerRadius(4)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                }
            }
        }
    }

    private func intensityColor(frp: Double) -> Color {
        switch frp {
        case ..<10: return .yellow
        case ..<50: return .orange
        case ..<100: return .red
        default: return .red
        }
    }

    private func confidenceColor(_ c: FireHotspot.FireConfidence) -> Color {
        switch c {
        case .high: return .red
        case .nominal: return .orange
        case .low: return .yellow
        }
    }
}

// MARK: - Fire Stats Bar

struct FireStatsBar: View {
    let hotspots: [FireHotspot]

    private var highCount: Int { hotspots.filter { $0.confidence == .high }.count }
    private var nominalCount: Int { hotspots.filter { $0.confidence == .nominal }.count }
    private var avgFRP: Double {
        guard !hotspots.isEmpty else { return 0 }
        return hotspots.reduce(0) { $0 + $1.frp } / Double(hotspots.count)
    }
    private var maxFRP: Double { hotspots.first?.frp ?? 0 }

    var body: some View {
        HStack(spacing: 24) {
            statItem("TOTAL", "\(hotspots.count)", .orange)
            statItem("HIGH CONF", "\(highCount)", .red)
            statItem("NOMINAL", "\(nominalCount)", .orange)
            statItem("AVG FRP", String(format: "%.1f MW", avgFRP), .yellow)
            statItem("MAX FRP", String(format: "%.1f MW", maxFRP), .red)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private func statItem(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Confidence Legend

struct ConfidenceLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            legendItem("HIGH", .red)
            legendItem("NOMINAL", .orange)
            legendItem("LOW", .yellow)
            Spacer()
            Text("FRP = Fire Radiative Power")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private func legendItem(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
