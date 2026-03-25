import SwiftUI
import MapKit

/// Screen 14: Satellite Orbits — CelesTrak constellation visualization.
/// Shows satellite positions with orbital track arcs on a dark globe.
struct SatelliteOrbitsScreenView: View {
    @ObservedObject var state: DashboardState

    /// Combine all satellite sources: Starlink (from space data) + GPS/Military (from gulf data)
    private var allSatellites: [APIService.SatellitePosition] {
        state.satellitePositions + state.militarySatellites
    }

    private var starlinkSats: [APIService.SatellitePosition] {
        allSatellites.filter { $0.group == "Starlink" }
    }
    private var gpsSats: [APIService.SatellitePosition] {
        allSatellites.filter { $0.group == "GPS" }
    }
    private var militarySats: [APIService.SatellitePosition] {
        allSatellites.filter { $0.group == "Military" }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left: Orbital map with ground tracks (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    "ORBITAL CONSTELLATION TRACKER",
                    subtitle: "\(allSatellites.count) SATELLITES TRACKED"
                )
                SatelliteOrbitMapView(satellites: allSatellites)
                    .frame(maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
                OrbitStatsBar(satellites: allSatellites)
            }
            .frame(maxWidth: .infinity)

            // Right: Constellation breakdown + satellite list
            VStack(spacing: 12) {
                sectionHeader("CONSTELLATIONS", subtitle: nil)
                ConstellationPanel(
                    starlink: starlinkSats,
                    gps: gpsSats,
                    military: militarySats
                )
                sectionHeader("ISS POSITION", subtitle: nil)
                OrbitISSPanel(position: state.issPosition)
                sectionHeader("SATELLITE LIST", subtitle: nil)
                SatelliteListPanel(satellites: allSatellites)
                    .frame(maxHeight: .infinity)
                OrbitLegend()
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

// MARK: - Satellite Map with Ground Track Polylines

struct SatelliteOrbitMapView: View {
    let satellites: [APIService.SatellitePosition]

    @State private var cameraPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        distance: 40_000_000
    ))

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            // Ground track polylines for GPS satellites (most visible, ~55° inclination)
            ForEach(satellites.filter { $0.group == "GPS" }) { sat in
                ForEach(0..<groundTrackSegments(for: sat).count, id: \.self) { idx in
                    MapPolyline(coordinates: groundTrackSegments(for: sat)[idx])
                        .stroke(.green.opacity(0.3), lineWidth: 1.5)
                }
            }

            // Ground track polylines for Military satellites
            ForEach(satellites.filter { $0.group == "Military" }) { sat in
                ForEach(0..<groundTrackSegments(for: sat).count, id: \.self) { idx in
                    MapPolyline(coordinates: groundTrackSegments(for: sat)[idx])
                        .stroke(.red.opacity(0.25), lineWidth: 1.2)
                }
            }

            // Ground track polylines for sample of Starlink (every 5th)
            ForEach(starlinkSample) { sat in
                ForEach(0..<groundTrackSegments(for: sat).count, id: \.self) { idx in
                    MapPolyline(coordinates: groundTrackSegments(for: sat)[idx])
                        .stroke(.white.opacity(0.08), lineWidth: 0.5)
                }
            }

            // Satellite position dots
            ForEach(satellites.prefix(400)) { sat in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: sat.latitude,
                    longitude: sat.longitude
                ), anchor: .center) {
                    OrbitSatDot(satellite: sat)
                }
            }

            // ISS marker if nearby data exists
        }
        .mapStyle(.imagery(elevation: .flat))
    }

    private var starlinkSample: [APIService.SatellitePosition] {
        let starlink = satellites.filter { $0.group == "Starlink" }
        return stride(from: 0, to: starlink.count, by: 5).map { starlink[$0] }
    }

    /// Generate ground track coordinate segments for a satellite.
    /// Returns multiple segments (split at ±180° longitude wrap).
    private func groundTrackSegments(for sat: APIService.SatellitePosition) -> [[CLLocationCoordinate2D]] {
        let inclination = estimateInclination(sat)
        let orbitalPeriod = estimateOrbitalPeriod(altitude: sat.altitude)

        var segments: [[CLLocationCoordinate2D]] = []
        var currentSegment: [CLLocationCoordinate2D] = []
        var prevLon: Double?

        let steps = 80
        for i in 0...steps {
            let fraction = Double(i) / Double(steps)

            // Longitude advances linearly
            let rawLon = sat.longitude + (fraction - 0.5) * 360.0 * (90.0 / orbitalPeriod)

            // Latitude oscillates sinusoidally based on inclination
            let clampedRatio = max(-1.0, min(1.0, sat.latitude / max(inclination, 1.0)))
            let phase = 2.0 * .pi * fraction + asin(clampedRatio)
            let lat = inclination * sin(phase)

            // Normalize longitude to -180...180
            var lon = rawLon.truncatingRemainder(dividingBy: 360.0)
            if lon > 180 { lon -= 360 }
            if lon < -180 { lon += 360 }

            // Clamp latitude
            let clampedLat = max(-85, min(85, lat))

            // Detect longitude wrap — break segment
            if let prev = prevLon, abs(lon - prev) > 90 {
                if currentSegment.count >= 2 {
                    segments.append(currentSegment)
                }
                currentSegment = []
            }

            currentSegment.append(CLLocationCoordinate2D(latitude: clampedLat, longitude: lon))
            prevLon = lon
        }

        if currentSegment.count >= 2 {
            segments.append(currentSegment)
        }

        return segments
    }

    private func estimateInclination(_ sat: APIService.SatellitePosition) -> Double {
        switch sat.group {
        case "Starlink": return 53.0
        case "GPS": return 55.0
        case "Military": return 65.0
        default: return 51.6
        }
    }

    private func estimateOrbitalPeriod(altitude: Double) -> Double {
        let r = 6371.0 + altitude
        let periodSeconds = 2.0 * .pi * sqrt(pow(r, 3) / 398600.4)
        return periodSeconds / 60.0
    }
}

// MARK: - Satellite Dot

struct OrbitSatDot: View {
    let satellite: APIService.SatellitePosition

    private var color: Color {
        switch satellite.group {
        case "Starlink": return .white.opacity(0.7)
        case "GPS": return .green
        case "Military": return .red
        default: return .cyan
        }
    }

    private var size: CGFloat {
        switch satellite.group {
        case "GPS": return 8
        case "Military": return 7
        default: return 3
        }
    }

    var body: some View {
        ZStack {
            if satellite.group == "GPS" || satellite.group == "Military" {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: size * 2.5, height: size * 2.5)
            }
            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Constellation Panel

struct ConstellationPanel: View {
    let starlink: [APIService.SatellitePosition]
    let gps: [APIService.SatellitePosition]
    let military: [APIService.SatellitePosition]

    var body: some View {
        VStack(spacing: 6) {
            constellationRow("STARLINK", count: starlink.count,
                           altitude: avgAlt(starlink), color: .white.opacity(0.8))
            constellationRow("GPS", count: gps.count,
                           altitude: avgAlt(gps), color: .green)
            constellationRow("MILITARY", count: military.count,
                           altitude: avgAlt(military), color: .red)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private func constellationRow(_ name: String, count: Int, altitude: Double, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(name)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
            Spacer()
            Text("\(count) sats")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(color)
            Text(String(format: "%.0f km", altitude))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 80, alignment: .trailing)
        }
    }

    private func avgAlt(_ sats: [APIService.SatellitePosition]) -> Double {
        guard !sats.isEmpty else { return 0 }
        return sats.reduce(0) { $0 + $1.altitude } / Double(sats.count)
    }
}

// MARK: - ISS Panel

struct OrbitISSPanel: View {
    let position: ISSPosition?

    var body: some View {
        if let iss = position {
            HStack(spacing: 12) {
                Image(systemName: "airplane")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.2f°N, %.2f°E", iss.latitude, iss.longitude))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                    Text("ALTITUDE ~408 km — SPEED ~27,600 km/h")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(10)
            .background(Color.yellow.opacity(0.05))
            .cornerRadius(8)
        } else {
            Text("ISS POSITION UNAVAILABLE")
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(.gray)
                .padding(10)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
        }
    }
}

// MARK: - Satellite List

struct SatelliteListPanel: View {
    let satellites: [APIService.SatellitePosition]

    /// Show GPS and military first, then sample of Starlink
    private var prioritySats: [APIService.SatellitePosition] {
        let gps = satellites.filter { $0.group == "GPS" }
        let mil = satellites.filter { $0.group == "Military" }
        let starlink = Array(satellites.filter { $0.group == "Starlink" }.prefix(10))
        return gps + mil + starlink
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 3) {
                ForEach(prioritySats) { sat in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(satColor(sat.group))
                            .frame(width: 6, height: 6)
                        Text(sat.name.prefix(20))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text(String(format: "%.0f km", sat.altitude))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(String(format: "%.1f°, %.1f°", sat.latitude, sat.longitude))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.5))
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
                }
            }
        }
    }

    private func satColor(_ group: String) -> Color {
        switch group {
        case "Starlink": return .white.opacity(0.6)
        case "GPS": return .green
        case "Military": return .red
        default: return .cyan
        }
    }
}

// MARK: - Orbit Stats Bar

struct OrbitStatsBar: View {
    let satellites: [APIService.SatellitePosition]

    private var starlinkCount: Int { satellites.filter { $0.group == "Starlink" }.count }
    private var gpsCount: Int { satellites.filter { $0.group == "GPS" }.count }
    private var milCount: Int { satellites.filter { $0.group == "Military" }.count }

    var body: some View {
        HStack(spacing: 24) {
            statItem("TOTAL", "\(satellites.count)", .cyan)
            statItem("STARLINK", "\(starlinkCount)", .white)
            statItem("GPS", "\(gpsCount)", .green)
            statItem("MILITARY", "\(milCount)", .red)
            statItem("SOURCE", "CELESTRAK", .gray)
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

// MARK: - Orbit Legend

struct OrbitLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                legendItem("STARLINK (LEO ~550km)", .white.opacity(0.6))
                legendItem("GPS (MEO ~20200km)", .green)
                legendItem("MILITARY", .red)
            }
            Text("Lines show approximate ground tracks")
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
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
