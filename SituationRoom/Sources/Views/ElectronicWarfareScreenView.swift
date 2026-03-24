import SwiftUI
import MapKit

/// Screen 12: Electronic Warfare — GPS jamming detection from ADS-B NACp analysis.
/// Hexagonal heatmap overlay showing probable GPS interference zones.
struct ElectronicWarfareScreenView: View {
    @ObservedObject var state: DashboardState

    /// Analyze all global flights for GPS degradation
    private var jammingZones: [JammingZone] {
        computeJammingZones(from: state.globalFlightPositions)
    }

    private var affectedAircraft: [APIService.FlightPosition] {
        state.globalFlightPositions.filter { $0.nacP < 8 }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left: Jamming heatmap (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    "GPS INTERFERENCE DETECTION",
                    subtitle: "\(jammingZones.count) ZONES — \(affectedAircraft.count) AFFECTED AIRCRAFT"
                )
                JammingMapView(
                    zones: jammingZones,
                    flights: state.globalFlightPositions
                )
                .frame(maxHeight: .infinity)
                EWStatsBar(
                    totalFlights: state.globalFlightPositions.count,
                    affectedCount: affectedAircraft.count,
                    zones: jammingZones
                )
            }
            .frame(maxWidth: .infinity)

            // Right: Intel panel
            VStack(spacing: 12) {
                sectionHeader("JAMMING ZONES", subtitle: nil)
                JammingZoneList(zones: jammingZones)
                    .frame(maxHeight: .infinity)
                sectionHeader("AFFECTED AIRCRAFT", subtitle: nil)
                AffectedAircraftList(flights: affectedAircraft)
                    .frame(maxHeight: .infinity)
                NACpLegend()
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
                    .foregroundColor(.yellow.opacity(0.8))
            }
            Spacer()
        }
    }
}

// MARK: - Jamming Zone Detection

/// A detected GPS interference zone from NACp clustering
struct JammingZone: Identifiable {
    let id: String
    let centerLat: Double
    let centerLon: Double
    let averageNACp: Double
    let aircraftCount: Int
    let regionName: String
    let severity: Severity

    enum Severity: String {
        case severe = "SEVERE"     // avg NACp < 4
        case moderate = "MODERATE" // avg NACp 4-6
        case low = "LOW"           // avg NACp 6-8

        var color: Color {
            switch self {
            case .severe: return .red
            case .moderate: return .orange
            case .low: return .yellow
            }
        }
    }
}

/// Grid-cluster flights by 5° cells, flag cells with low average NACp
private func computeJammingZones(from flights: [APIService.FlightPosition]) -> [JammingZone] {
    // Group flights into 5°×5° grid cells
    var cells: [String: (lats: [Double], lons: [Double], nacPs: [Int])] = [:]

    for f in flights where f.nacP < 11 { // Only count aircraft with reported NACp
        let gridLat = (f.latitude / 5.0).rounded(.down) * 5.0
        let gridLon = (f.longitude / 5.0).rounded(.down) * 5.0
        let key = "\(Int(gridLat))_\(Int(gridLon))"

        var cell = cells[key] ?? (lats: [], lons: [], nacPs: [])
        cell.lats.append(f.latitude)
        cell.lons.append(f.longitude)
        cell.nacPs.append(f.nacP)
        cells[key] = cell
    }

    // Flag cells where average NACp < 8 and at least 2 aircraft affected
    return cells.compactMap { key, cell -> JammingZone? in
        let avgNACp = Double(cell.nacPs.reduce(0, +)) / Double(cell.nacPs.count)
        let lowCount = cell.nacPs.filter { $0 < 8 }.count
        guard avgNACp < 8, lowCount >= 2 else { return nil }

        let centerLat = cell.lats.reduce(0, +) / Double(cell.lats.count)
        let centerLon = cell.lons.reduce(0, +) / Double(cell.lons.count)

        let severity: JammingZone.Severity
        if avgNACp < 4 { severity = .severe }
        else if avgNACp < 6 { severity = .moderate }
        else { severity = .low }

        return JammingZone(
            id: key,
            centerLat: centerLat,
            centerLon: centerLon,
            averageNACp: avgNACp,
            aircraftCount: lowCount,
            regionName: regionName(lat: centerLat, lon: centerLon),
            severity: severity
        )
    }
    .sorted { $0.averageNACp < $1.averageNACp } // Worst first
}

private func regionName(lat: Double, lon: Double) -> String {
    // Known GPS jamming hotspots
    if lat > 30 && lat < 40 && lon > 30 && lon < 40 { return "Eastern Mediterranean" }
    if lat > 53 && lat < 60 && lon > 18 && lon < 25 { return "Baltic / Kaliningrad" }
    if lat > 40 && lat < 48 && lon > 26 && lon < 42 { return "Black Sea" }
    if lat > 30 && lat < 38 && lon > 42 && lon < 52 { return "Iraq / Iran Border" }
    if lat > 32 && lat < 42 && lon > 55 && lon < 70 { return "Iran / Afghanistan" }
    if lat > 60 && lat < 72 && lon > 25 && lon < 45 { return "Northern Norway / Finland" }
    if lat > 20 && lat < 30 && lon > 30 && lon < 40 { return "Red Sea / Egypt" }
    if lat > 48 && lat < 55 && lon > 30 && lon < 42 { return "Ukraine / Western Russia" }
    if lat > 35 && lat < 42 && lon > 24 && lon < 30 { return "Aegean Sea" }
    // Generic
    if lat > 35 && lat < 72 && lon > -11 && lon < 40 { return "Europe" }
    if lat > 5 && lat < 55 && lon > 60 && lon < 150 { return "Asia" }
    if lat > 24 && lat < 50 && lon > -125 && lon < -66 { return "North America" }
    if lat > -35 && lat < 37 && lon > -18 && lon < 52 { return "Africa" }
    return "Region \(Int(lat))°, \(Int(lon))°"
}

// MARK: - Jamming Map View

struct JammingMapView: View {
    let zones: [JammingZone]
    let flights: [APIService.FlightPosition]

    @State private var cameraPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 35, longitude: 30),
        distance: 25_000_000 // Focus on Middle East/Europe where jamming is most common
    ))

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            // Jamming zone overlays
            ForEach(zones) { zone in
                // Zone circle
                MapCircle(
                    center: CLLocationCoordinate2D(latitude: zone.centerLat, longitude: zone.centerLon),
                    radius: 250_000 // 250km radius
                )
                .foregroundStyle(zone.severity.color.opacity(0.15))
                .stroke(zone.severity.color.opacity(0.6), lineWidth: 2)

                // Zone label
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: zone.centerLat,
                    longitude: zone.centerLon
                ), anchor: .center) {
                    VStack(spacing: 2) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 16))
                            .foregroundColor(zone.severity.color)
                        Text("NACp \(String(format: "%.1f", zone.averageNACp))")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundColor(zone.severity.color)
                    }
                }
            }

            // Affected aircraft (low NACp)
            ForEach(flights.filter { $0.nacP < 8 }.prefix(200)) { flight in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: flight.latitude,
                    longitude: flight.longitude
                ), anchor: .center) {
                    Circle()
                        .fill(nacPColor(flight.nacP))
                        .frame(width: 5, height: 5)
                }
            }
        }
        .mapStyle(.imagery(elevation: .flat))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
    }

    private func nacPColor(_ nacP: Int) -> Color {
        switch nacP {
        case ..<4: return .red
        case ..<6: return .orange
        case ..<8: return .yellow
        default: return .green.opacity(0.3)
        }
    }
}

// MARK: - Jamming Zone List

struct JammingZoneList: View {
    let zones: [JammingZone]

    var body: some View {
        if zones.isEmpty {
            VStack {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 28))
                    .foregroundColor(.green.opacity(0.6))
                Text("NO JAMMING DETECTED")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.green.opacity(0.6))
                Text("All monitored GPS signals nominal")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(zones) { zone in
                        HStack(spacing: 10) {
                            // Severity badge
                            Text(zone.severity.rawValue)
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(zone.severity.color)
                                .cornerRadius(4)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(zone.regionName.uppercased())
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))
                                Text("\(zone.aircraftCount) aircraft — avg NACp \(String(format: "%.1f", zone.averageNACp))")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 8)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(6)
                    }
                }
            }
        }
    }
}

// MARK: - Affected Aircraft List

struct AffectedAircraftList: View {
    let flights: [APIService.FlightPosition]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 4) {
                ForEach(flights.sorted(by: { $0.nacP < $1.nacP }).prefix(12)) { flight in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(nacPColor(flight.nacP))
                            .frame(width: 8, height: 8)
                        Text(flight.callsign.isEmpty ? flight.id.uppercased() : flight.callsign)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("NACp \(flight.nacP)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(nacPColor(flight.nacP))
                        Text("FL\(Int(flight.altitude / 100))")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }

    private func nacPColor(_ nacP: Int) -> Color {
        switch nacP {
        case ..<4: return .red
        case ..<6: return .orange
        case ..<8: return .yellow
        default: return .green
        }
    }
}

// MARK: - EW Stats Bar

struct EWStatsBar: View {
    let totalFlights: Int
    let affectedCount: Int
    let zones: [JammingZone]

    private var severeCount: Int { zones.filter { $0.severity == .severe }.count }
    private var moderateCount: Int { zones.filter { $0.severity == .moderate }.count }

    var body: some View {
        HStack(spacing: 24) {
            statItem("ANALYZED", "\(totalFlights)", .cyan)
            statItem("AFFECTED", "\(affectedCount)", affectedCount > 0 ? .yellow : .green)
            statItem("ZONES", "\(zones.count)", zones.isEmpty ? .green : .orange)
            statItem("SEVERE", "\(severeCount)", severeCount > 0 ? .red : .green)
            statItem("MODERATE", "\(moderateCount)", moderateCount > 0 ? .orange : .green)
            statItem("SOURCE", "ADSB.LOL NACp", .gray)
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

// MARK: - NACp Legend

struct NACpLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                legendItem("0-3 SEVERE", .red)
                legendItem("4-5 MODERATE", .orange)
                legendItem("6-7 LOW", .yellow)
                legendItem("8+ NOMINAL", .green)
            }
            Text("NACp = Navigation Accuracy Category (position)")
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private func legendItem(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
