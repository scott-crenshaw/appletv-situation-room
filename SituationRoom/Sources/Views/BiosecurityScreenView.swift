import SwiftUI
import MapKit

/// Screen 15: Pandemic & Biosecurity Threat Board — WHO outbreak alerts on dark map.
/// Biohazard markers at outbreak locations + disease.sh health baseline layer.
struct BiosecurityScreenView: View {
    @ObservedObject var state: DashboardState

    private var recentAlerts: [OutbreakAlert] {
        // Only show alerts from last 12 months
        let cutoff = Calendar.current.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        return state.outbreakAlerts.filter { $0.date > cutoff }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left: Outbreak map (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    "GLOBAL OUTBREAK SURVEILLANCE",
                    subtitle: "\(recentAlerts.count) ACTIVE ALERTS — WHO DON"
                )
                OutbreakMapView(
                    alerts: recentAlerts,
                    healthData: state.globalHealthData
                )
                .frame(maxHeight: .infinity)
                BiosecurityStatsBar(
                    alerts: recentAlerts,
                    healthData: state.globalHealthData
                )
            }
            .frame(maxWidth: .infinity)

            // Right: Outbreak feed + pathogen index
            VStack(spacing: 12) {
                sectionHeader("ACTIVE OUTBREAKS", subtitle: nil)
                OutbreakFeed(alerts: recentAlerts)
                    .frame(maxHeight: .infinity)
                sectionHeader("PATHOGEN INDEX", subtitle: nil)
                PathogenIndex(alerts: recentAlerts)
                sectionHeader("WHO REGIONS", subtitle: nil)
                RegionalThreatGauges(alerts: recentAlerts)
                BiosecurityLegend()
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

// MARK: - Outbreak Map

struct OutbreakMapView: View {
    let alerts: [OutbreakAlert]
    let healthData: [CountryHealthData]

    @State private var cameraPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 15),
        distance: 40_000_000
    ))

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            // Background layer: disease.sh country health dots (subtle)
            ForEach(healthData.prefix(40)) { country in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: country.latitude,
                    longitude: country.longitude
                ), anchor: .center) {
                    HealthDot(data: country)
                }
            }

            // Foreground: WHO outbreak markers (prominent)
            ForEach(alerts) { alert in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: alert.latitude,
                    longitude: alert.longitude
                ), anchor: .center) {
                    OutbreakMarker(alert: alert)
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

// MARK: - Health Dot (background layer)

struct HealthDot: View {
    let data: CountryHealthData

    private var dotSize: CGFloat {
        let normalized = min(data.activePerMillion / 50000, 1.0)
        return 3 + normalized * 5
    }

    var body: some View {
        Circle()
            .fill(Color.cyan.opacity(0.15))
            .frame(width: dotSize, height: dotSize)
    }
}

// MARK: - Outbreak Marker (biohazard icon with pulsing ring)

struct OutbreakMarker: View {
    let alert: OutbreakAlert
    @State private var isPulsing = false

    private var markerColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .high: return .orange
        case .elevated: return .yellow
        case .low: return .green
        }
    }

    private var ringSize: CGFloat {
        switch alert.bslLevel {
        case 4: return 40
        case 3: return 30
        default: return 22
        }
    }

    var body: some View {
        ZStack {
            // Pulsing containment ring
            Circle()
                .stroke(markerColor.opacity(0.4), lineWidth: 1.5)
                .frame(width: ringSize, height: ringSize)
                .scaleEffect(isPulsing ? 1.6 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.6)

            // Outer glow
            Circle()
                .fill(markerColor.opacity(0.2))
                .frame(width: ringSize * 0.7, height: ringSize * 0.7)

            // Core biohazard icon
            Image(systemName: "biohazard")
                .font(.system(size: alert.bslLevel >= 4 ? 16 : 12, weight: .bold))
                .foregroundColor(markerColor)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Outbreak Feed (right panel)

struct OutbreakFeed: View {
    let alerts: [OutbreakAlert]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(alerts) { alert in
                    OutbreakCard(alert: alert)
                }
            }
        }
    }
}

struct OutbreakCard: View {
    let alert: OutbreakAlert

    private var severityColor: Color {
        switch alert.severity {
        case .critical: return .red
        case .high: return .orange
        case .elevated: return .yellow
        case .low: return .green
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "biohazard")
                    .font(.system(size: 11))
                    .foregroundColor(severityColor)
                Text(alert.disease.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(severityColor)
                Spacer()
                Text("BSL-\(alert.bslLevel)")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(3)
            }
            HStack {
                Text(alert.country)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                Text("·")
                    .foregroundColor(.gray)
                Text(alert.ageDescription)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            }
            // Severity bar
            HStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(severityColor)
                            .frame(width: geo.size.width * severityFraction, height: 4)
                    }
                }
                .frame(height: 4)
                Text(alert.severity.rawValue)
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(severityColor)
                    .frame(width: 65, alignment: .trailing)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(severityColor.opacity(0.15), lineWidth: 1)
        )
    }

    private var severityFraction: CGFloat {
        switch alert.severity {
        case .critical: return 1.0
        case .high: return 0.75
        case .elevated: return 0.5
        case .low: return 0.25
        }
    }
}

// MARK: - Pathogen Index

struct PathogenIndex: View {
    let alerts: [OutbreakAlert]

    private var bslCounts: [(level: Int, count: Int, color: Color)] {
        let levels: [(Int, Color)] = [(4, .red), (3, .orange), (2, .yellow)]
        return levels.map { level, color in
            (level, alerts.filter { $0.bslLevel == level }.count, color)
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            ForEach(bslCounts, id: \.level) { level, count, color in
                HStack {
                    Text("BSL-\(level)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(color)
                    Spacer()
                    // Dot indicators
                    HStack(spacing: 3) {
                        ForEach(0..<max(count, 0), id: \.self) { _ in
                            Circle()
                                .fill(color)
                                .frame(width: 8, height: 8)
                        }
                        if count == 0 {
                            Text("NONE")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    Text("(\(count))")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Regional Threat Gauges

struct RegionalThreatGauges: View {
    let alerts: [OutbreakAlert]

    private var regionData: [(region: WHORegion, count: Int, maxSeverity: BiosecurityLevel)] {
        WHORegion.allCases.map { region in
            let regionAlerts = alerts.filter { WHORegion.fromCountry($0.country) == region }
            let maxSev = regionAlerts.map(\.severity).min(by: { sevOrder($0) < sevOrder($1) }) ?? .low
            return (region, regionAlerts.count, maxSev)
        }
        .sorted { sevOrder($0.maxSeverity) < sevOrder($1.maxSeverity) }
    }

    private func sevOrder(_ s: BiosecurityLevel) -> Int {
        switch s {
        case .critical: return 0
        case .high: return 1
        case .elevated: return 2
        case .low: return 3
        }
    }

    var body: some View {
        VStack(spacing: 3) {
            ForEach(regionData, id: \.region) { region, count, severity in
                HStack(spacing: 8) {
                    Text(region.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 55, alignment: .leading)
                    // Gauge bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.white.opacity(0.08))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(gaugeColor(severity))
                                .frame(width: geo.size.width * gaugeFraction(count), height: 6)
                        }
                    }
                    .frame(height: 6)
                    Text(count > 0 ? severity.rawValue : "CLEAR")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(count > 0 ? gaugeColor(severity) : .green.opacity(0.5))
                        .frame(width: 65, alignment: .trailing)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private func gaugeColor(_ severity: BiosecurityLevel) -> Color {
        switch severity {
        case .critical: return .red
        case .high: return .orange
        case .elevated: return .yellow
        case .low: return .green
        }
    }

    private func gaugeFraction(_ count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        return min(CGFloat(count) / 5.0, 1.0)
    }
}

// MARK: - Stats Bar

struct BiosecurityStatsBar: View {
    let alerts: [OutbreakAlert]
    let healthData: [CountryHealthData]

    private var criticalCount: Int { alerts.filter { $0.severity == .critical }.count }
    private var highCount: Int { alerts.filter { $0.severity == .high }.count }
    private var uniquePathogens: Int { Set(alerts.map(\.disease)).count }
    private var affectedCountries: Int { Set(alerts.map(\.country)).count }
    private var topBSL: Int { alerts.map(\.bslLevel).max() ?? 0 }

    var body: some View {
        HStack(spacing: 24) {
            statItem("ALERTS", "\(alerts.count)", .cyan)
            statItem("CRITICAL", "\(criticalCount)", criticalCount > 0 ? .red : .gray)
            statItem("HIGH", "\(highCount)", highCount > 0 ? .orange : .gray)
            statItem("PATHOGENS", "\(uniquePathogens)", .cyan)
            statItem("COUNTRIES", "\(affectedCountries)", .cyan)
            statItem("MAX BSL", topBSL > 0 ? "BSL-\(topBSL)" : "—", topBSL >= 4 ? .red : .orange)
            statItem("SOURCE", "WHO DON", .gray)
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

// MARK: - Legend

struct BiosecurityLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            legendItem("BSL-4 CRITICAL", .red)
            legendItem("BSL-3 HIGH", .orange)
            legendItem("BSL-2 ELEVATED", .yellow)
            legendItem("BASELINE", .cyan.opacity(0.4))
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
