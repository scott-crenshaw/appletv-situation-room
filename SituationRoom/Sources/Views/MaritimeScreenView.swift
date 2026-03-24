import SwiftUI
import MapKit

/// Screen 13: Maritime Surveillance — AIS vessel tracking (Baltic Sea).
/// Ship icons on dark satellite map + vessel table.
struct MaritimeScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left: Vessel map (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    "BALTIC SEA AIS TRACKING",
                    subtitle: "\(state.maritimeVessels.count) VESSELS — FINNISH DIGITRAFFIC"
                )
                VesselMapView(vessels: state.maritimeVessels)
                    .frame(maxHeight: .infinity)
                MaritimeStatsBar(vessels: state.maritimeVessels)
            }
            .frame(maxWidth: .infinity)

            // Right: Vessel table
            VStack(spacing: 12) {
                sectionHeader("VESSEL REGISTRY", subtitle: nil)
                VesselTypeBreakdown(vessels: state.maritimeVessels)
                sectionHeader("ACTIVE VESSELS", subtitle: nil)
                VesselTable(vessels: state.maritimeVessels)
                    .frame(maxHeight: .infinity)
                VesselLegend()
            }
            .frame(width: 560)
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
                    .foregroundColor(.cyan.opacity(0.8))
            }
            Spacer()
        }
    }
}

// MARK: - Vessel Map

struct VesselMapView: View {
    let vessels: [APIService.MaritimeVessel]

    // Baltic Sea center
    @State private var cameraPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 59.5, longitude: 22.0),
        distance: 2_500_000
    ))

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
    }
}

// MARK: - Vessel Dot

struct VesselDot: View {
    let vessel: APIService.MaritimeVessel

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
            // Direction indicator for moving vessels
            if vessel.isMoving && vessel.heading > 0 && vessel.heading < 360 {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 6))
                    .foregroundColor(color)
                    .rotationEffect(.degrees(vessel.heading))
                    .offset(y: -6)
            }
            Circle()
                .fill(color)
                .frame(width: vessel.isMoving ? 5 : 3, height: vessel.isMoving ? 5 : 3)
        }
    }
}

// MARK: - Vessel Type Breakdown

struct VesselTypeBreakdown: View {
    let vessels: [APIService.MaritimeVessel]

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
    let vessels: [APIService.MaritimeVessel]

    /// Show moving vessels first, sorted by speed
    private var sortedVessels: [APIService.MaritimeVessel] {
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
                            Text("→ " + vessel.destination.prefix(12))
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
    let vessels: [APIService.MaritimeVessel]

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
            statItem("COVERAGE", "BALTIC SEA", .gray)
            statItem("SOURCE", "DIGITRAFFIC AIS", .gray)
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
