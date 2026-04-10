import SwiftUI
import MapKit

/// Screen 13: Maritime Surveillance — AIS vessel tracking across 5 global regions.
/// Cycles through regions at 30s each (150s total). Ship icons on dark satellite map + vessel table.
struct MaritimeScreenView: View {
    @ObservedObject var state: DashboardState
    @State private var currentRegionIndex = 0

    private var region: MaritimeRegion {
        MaritimeRegion.allCases[currentRegionIndex]
    }

    private var vessels: [MaritimeVessel] {
        state.maritimeStream.vesselsByRegion[region] ?? []
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left: Vessel map (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    region.name,
                    subtitle: "\(vessels.count) VESSELS — AISSTREAM.IO"
                )
                if !state.maritimeStream.hasAPIKey {
                    apiKeyMissingView
                } else {
                    RegionalVesselMapView(vessels: vessels, region: region)
                        .frame(maxHeight: .infinity)
                    MaritimeStatsBar(vessels: vessels, region: region,
                                     isConnected: state.maritimeStream.isConnected)
                }
            }
            .frame(maxWidth: .infinity)

            // Right: Vessel table
            VStack(spacing: 12) {
                sectionHeader("VESSEL REGISTRY", subtitle: nil)
                VesselTypeBreakdown(vessels: vessels)
                sectionHeader("ACTIVE VESSELS", subtitle: nil)
                VesselTable(vessels: vessels)
                    .frame(maxHeight: .infinity)
                regionIndicator
                VesselLegend()
            }
            .frame(width: 560)
        }
        .padding(24)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            let elapsed = now.timeIntervalSince(state.screenStartedAt)
            let phase = min(Int(elapsed / 30), MaritimeRegion.allCases.count - 1)
            if phase != currentRegionIndex {
                withAnimation(.easeInOut(duration: 1.5)) {
                    currentRegionIndex = phase
                }
            }
        }
        .onChange(of: state.currentScreen) {
            currentRegionIndex = 0
        }
    }

    private var apiKeyMissingView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "key.slash")
                .font(.system(size: 48))
                .foregroundColor(.red.opacity(0.6))
            Text("AISSTREAM API KEY REQUIRED")
                .font(.system(size: 18, weight: .heavy, design: .monospaced))
                .foregroundColor(.red.opacity(0.8))
            Text("Add your key to Secrets.plist")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
        }
    }

    private var regionIndicator: some View {
        HStack(spacing: 8) {
            ForEach(MaritimeRegion.allCases, id: \.rawValue) { r in
                RoundedRectangle(cornerRadius: 2)
                    .fill(r == region ? Color.cyan : Color.white.opacity(0.15))
                    .frame(width: r == region ? 24 : 12, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentRegionIndex)
            }
        }
        .padding(.vertical, 4)
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
                    .foregroundColor(.cyan.opacity(0.8))
            }
            Spacer()
        }
    }
}

// MARK: - Regional Vessel Map

struct RegionalVesselMapView: View {
    let vessels: [MaritimeVessel]
    let region: MaritimeRegion

    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            ForEach(vessels.prefix(500)) { vessel in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: vessel.latitude,
                    longitude: vessel.longitude
                ), anchor: .center) {
                    VesselDot(vessel: vessel)
                }
            }
        }
        .mapStyle(.imagery(elevation: .flat))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            cameraPosition = .camera(MapCamera(
                centerCoordinate: region.mapCenter,
                distance: region.mapDistance
            ))
        }
        .onChange(of: region) { _, newRegion in
            withAnimation(.easeInOut(duration: 2.0)) {
                cameraPosition = .camera(MapCamera(
                    centerCoordinate: newRegion.mapCenter,
                    distance: newRegion.mapDistance
                ))
            }
        }
    }
}

// MARK: - Vessel Dot

struct VesselDot: View {
    let vessel: MaritimeVessel

    private var color: Color {
        switch vessel.shipType {
        case 35: return .red          // Military
        case 60...69: return .blue    // Passenger
        case 70...79: return .green   // Cargo
        case 80...89: return .orange  // Tanker
        case 30: return .cyan         // Fishing
        case 51: return .yellow       // SAR
        default: return .white.opacity(0.4)
        }
    }

    var body: some View {
        ZStack {
            // Glow halo for visibility at wide zoom
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: vessel.isMoving ? 14 : 10, height: vessel.isMoving ? 14 : 10)
            if vessel.isMoving && vessel.heading > 0 && vessel.heading < 360 {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 8))
                    .foregroundColor(color)
                    .rotationEffect(.degrees(vessel.heading))
                    .offset(y: -8)
            }
            Circle()
                .fill(color)
                .frame(width: vessel.isMoving ? 8 : 5, height: vessel.isMoving ? 8 : 5)
        }
    }
}

// MARK: - Vessel Type Breakdown

struct VesselTypeBreakdown: View {
    let vessels: [MaritimeVessel]

    private var typeCounts: [(String, Int, Color)] {
        let types: [(String, ClosedRange<Int>, Color)] = [
            ("CARGO", 70...79, .green),
            ("TANKER", 80...89, .orange),
            ("PASSENGER", 60...69, .blue),
            ("FISHING", 30...30, .cyan),
            ("MILITARY", 35...35, .red),
        ]
        return types.map { name, range, color in
            (name, vessels.filter { range.contains($0.shipType) }.count, color)
        }.filter { $0.1 > 0 }
    }

    var body: some View {
        VStack(spacing: 4) {
            ForEach(typeCounts, id: \.0) { type, count, color in
                HStack {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(type)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("\(count)")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(color)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Vessel Table

struct VesselTable: View {
    let vessels: [MaritimeVessel]

    private var sortedVessels: [MaritimeVessel] {
        vessels.sorted { $0.sog > $1.sog }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 4) {
                ForEach(sortedVessels.prefix(20)) { vessel in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(vesselColor(vessel.shipType))
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(vessel.name.prefix(20))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                            Text(vessel.shipTypeText)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        if !vessel.destination.isEmpty {
                            Text("\u{2192} " + vessel.destination.prefix(12))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.6))
                        }
                        Text(String(format: "%.1f kn", vessel.sog))
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(vessel.isMoving ? .green : .gray)
                    }
                    .padding(.vertical, 3)
                    .padding(.horizontal, 6)
                    .background(Color.white.opacity(0.02))
                    .cornerRadius(4)
                }
            }
        }
    }

    private func vesselColor(_ type: Int) -> Color {
        switch type {
        case 35: return .red
        case 60...69: return .blue
        case 70...79: return .green
        case 80...89: return .orange
        case 30: return .cyan
        default: return .gray
        }
    }
}

// MARK: - Maritime Stats Bar

struct MaritimeStatsBar: View {
    let vessels: [MaritimeVessel]
    let region: MaritimeRegion
    let isConnected: Bool

    private var movingCount: Int { vessels.filter { $0.isMoving }.count }
    private var avgSpeed: Double {
        let moving = vessels.filter { $0.isMoving }
        guard !moving.isEmpty else { return 0 }
        return moving.reduce(0) { $0 + $1.sog } / Double(moving.count)
    }

    var body: some View {
        HStack(spacing: 24) {
            statItem("VESSELS", "\(vessels.count)", .cyan)
            statItem("UNDERWAY", "\(movingCount)", .green)
            statItem("STATIONARY", "\(vessels.count - movingCount)", .gray)
            statItem("AVG SPEED", String(format: "%.1f kn", avgSpeed), .cyan)
            statItem("REGION", String(region.name.prefix(20)).uppercased(), .gray)
            statItem("LINK", isConnected ? "LIVE" : "DOWN", isConnected ? .green : .red)
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

// MARK: - Vessel Legend

struct VesselLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            legendItem("CARGO", .green)
            legendItem("TANKER", .orange)
            legendItem("PASSENGER", .blue)
            legendItem("FISHING", .cyan)
            legendItem("MILITARY", .red)
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private func legendItem(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
