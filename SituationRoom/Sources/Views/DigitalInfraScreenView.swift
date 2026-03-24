import SwiftUI
import MapKit

/// Screen 11: Digital Infrastructure — submarine cables + internet outages.
/// Glowing cable lines on dark ocean with pulsing outage nodes.
struct DigitalInfraScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left: Cable + outage map (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    "SUBSEA CABLE NETWORK",
                    subtitle: "\(state.submarineCables.count) CABLES — \(state.internetOutages.count) OUTAGES"
                )
                CableMapView(cables: state.submarineCables, outages: state.internetOutages)
                    .frame(maxHeight: .infinity)
                InfraStatsBar(cables: state.submarineCables, outages: state.internetOutages)
            }
            .frame(maxWidth: .infinity)

            // Right: Outage feed + cable stats
            VStack(spacing: 12) {
                sectionHeader("ACTIVE OUTAGES", subtitle: nil)
                OutageFeed(outages: state.internetOutages)
                    .frame(maxHeight: .infinity)
                sectionHeader("NETWORK STATUS", subtitle: nil)
                CableRegionStats(cables: state.submarineCables)
                CableSourceLegend()
            }
            .frame(width: 500)
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

// MARK: - Cable Map (MapKit with polyline overlays + outage annotations)

struct CableMapView: View {
    let cables: [SubmarineCable]
    let outages: [InternetOutage]

    @State private var cameraPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        distance: 40_000_000
    ))

    /// Sample cables for performance — show up to 150 cables
    private var displayCables: [SubmarineCable] {
        Array(cables.prefix(150))
    }

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            // Submarine cables as polylines
            ForEach(displayCables) { cable in
                ForEach(0..<cable.coordinates.count, id: \.self) { segIdx in
                    let segment = cable.coordinates[segIdx]
                    if segment.count >= 2 {
                        MapPolyline(coordinates: segment)
                            .stroke(cableColor(cable.color), lineWidth: 1.2)
                    }
                }
            }

            // Outage markers
            ForEach(outages) { outage in
                Annotation("", coordinate: outage.coordinate, anchor: .center) {
                    OutageNode(outage: outage)
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

    private func cableColor(_ hex: String) -> Color {
        // Parse hex color, default to cyan
        let cleaned = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard cleaned.count == 6,
              let rgb = UInt64(cleaned, radix: 16) else {
            return .cyan.opacity(0.5)
        }
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        return Color(red: r, green: g, blue: b).opacity(0.7)
    }
}

// MARK: - Outage Node (pulsing red/orange marker on map)

struct OutageNode: View {
    let outage: InternetOutage
    @State private var isPulsing = false

    private var nodeColor: Color {
        outage.level == .critical ? .red : .orange
    }

    var body: some View {
        ZStack {
            // Pulse ring
            Circle()
                .stroke(nodeColor.opacity(isPulsing ? 0.0 : 0.6), lineWidth: 2)
                .frame(width: isPulsing ? 40 : 16, height: isPulsing ? 40 : 16)

            // Outer glow
            Circle()
                .fill(nodeColor.opacity(0.2))
                .frame(width: 20, height: 20)

            // Core
            Circle()
                .fill(nodeColor)
                .frame(width: 10, height: 10)

            // Label
            Text(outage.entityCode.uppercased())
                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .offset(y: 16)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Outage Feed (right panel list)

struct OutageFeed: View {
    let outages: [InternetOutage]

    var body: some View {
        if outages.isEmpty {
            VStack {
                Text("NO ACTIVE OUTAGES")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.green.opacity(0.6))
                Text("All monitored networks operational")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(outages) { outage in
                        HStack(spacing: 10) {
                            // Severity indicator
                            Circle()
                                .fill(outage.level == .critical ? Color.red : Color.orange)
                                .frame(width: 10, height: 10)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(outage.entityName.uppercased())
                                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))
                                HStack(spacing: 8) {
                                    Text(outage.level.rawValue.uppercased())
                                        .font(.system(size: 11, weight: .heavy, design: .monospaced))
                                        .foregroundColor(outage.level == .critical ? .red : .orange)
                                    Text(outage.datasource.uppercased())
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.gray)
                                }
                            }

                            Spacer()

                            Text(outage.entityCode.uppercased())
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.7))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
}

// MARK: - Cable Region Stats

struct CableRegionStats: View {
    let cables: [SubmarineCable]

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("TOTAL CABLES")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(cables.count)")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
            }

            HStack {
                Text("TOTAL SEGMENTS")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(cables.reduce(0) { $0 + $1.coordinates.count })")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.7))
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Infrastructure Stats Bar

struct InfraStatsBar: View {
    let cables: [SubmarineCable]
    let outages: [InternetOutage]

    private var criticalCount: Int { outages.filter { $0.level == .critical }.count }
    private var warningCount: Int { outages.filter { $0.level == .warning }.count }

    var body: some View {
        HStack(spacing: 24) {
            statItem("CABLES", "\(cables.count)", .cyan)
            statItem("OUTAGES", "\(outages.count)", outages.isEmpty ? .green : .red)
            statItem("CRITICAL", "\(criticalCount)", criticalCount > 0 ? .red : .green)
            statItem("WARNING", "\(warningCount)", warningCount > 0 ? .orange : .green)
            statItem("DATA SOURCES", "BGP / PING / MERIT-NT", .gray)
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

// MARK: - Source Legend

struct CableSourceLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            legendItem("CABLE", .cyan)
            legendItem("CRITICAL", .red)
            legendItem("WARNING", .orange)
            Spacer()
            Text("IODA + TeleGeography")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private func legendItem(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.7))
                .frame(width: 16, height: 3)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
