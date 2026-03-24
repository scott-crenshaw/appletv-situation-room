import SwiftUI
import MapKit

/// Screen 14: Satellite Orbits — CelesTrak constellation visualization.
/// Shows satellite positions with orbital track arcs on a dark globe.
struct SatelliteOrbitsScreenView: View {
    @ObservedObject var state: DashboardState

    private var starlinkSats: [APIService.SatellitePosition] {
        state.satellitePositions.filter { $0.group == "Starlink" }
    }
    private var gpsSats: [APIService.SatellitePosition] {
        state.satellitePositions.filter { $0.group == "GPS" }
    }
    private var militarySats: [APIService.SatellitePosition] {
        state.satellitePositions.filter { $0.group == "Military" }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left: Orbital map + ground track canvas (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    "ORBITAL CONSTELLATION TRACKER",
                    subtitle: "\(state.satellitePositions.count) SATELLITES TRACKED"
                )
                ZStack {
                    // Base satellite map
                    SatelliteOrbitMapView(satellites: state.satellitePositions)
                    // Overlay: ground track arcs drawn via Canvas
                    GroundTrackOverlay(satellites: state.satellitePositions)
                        .allowsHitTesting(false)
                }
                .frame(maxHeight: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                )
                OrbitStatsBar(satellites: state.satellitePositions)
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
                SatelliteListPanel(satellites: state.satellitePositions)
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

// MARK: - Satellite Map (MapKit with constellation markers)

struct SatelliteOrbitMapView: View {
    let satellites: [APIService.SatellitePosition]

    @State private var cameraPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        distance: 40_000_000
    ))

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            // Satellite annotations — limit for performance
            ForEach(satellites.prefix(400)) { sat in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: sat.latitude,
                    longitude: sat.longitude
                ), anchor: .center) {
                    OrbitSatDot(satellite: sat)
                }
            }
        }
        .mapStyle(.imagery(elevation: .flat))
    }
}

// MARK: - Satellite Dot

struct OrbitSatDot: View {
    let satellite: APIService.SatellitePosition

    private var color: Color {
        switch satellite.group {
        case "Starlink": return .white.opacity(0.6)
        case "GPS": return .green
        case "Military": return .red
        default: return .cyan
        }
    }

    private var size: CGFloat {
        switch satellite.group {
        case "GPS", "Military": return 6
        default: return 3
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

// MARK: - Ground Track Overlay (Canvas-drawn orbital arcs)

struct GroundTrackOverlay: View {
    let satellites: [APIService.SatellitePosition]

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                // Draw faint orbital arcs for GPS and Military satellites
                // These are approximate sinusoidal ground tracks
                let importantSats = satellites.filter { $0.group == "GPS" || $0.group == "Military" }

                for sat in importantSats {
                    drawGroundTrack(context: context, size: size, satellite: sat)
                }

                // Draw a sample of Starlink tracks (every 10th)
                let starlinkSample = satellites.filter { $0.group == "Starlink" }
                    .enumerated().filter { $0.offset % 10 == 0 }.map { $0.element }
                for sat in starlinkSample {
                    drawGroundTrack(context: context, size: size, satellite: sat)
                }
            }
        }
    }

    private func drawGroundTrack(context: GraphicsContext, size: CGSize, satellite: APIService.SatellitePosition) {
        // Approximate ground track as a sinusoidal path
        // Inclination determines latitude amplitude, current position sets phase
        let inclination = estimateInclination(satellite)
        let orbitalPeriod = estimateOrbitalPeriod(altitude: satellite.altitude)
        let color: Color = satellite.group == "Starlink" ? .white.opacity(0.06) :
                           satellite.group == "GPS" ? .green.opacity(0.15) : .red.opacity(0.2)
        let lineWidth: CGFloat = satellite.group == "Starlink" ? 0.5 : 1.0

        var path = Path()
        let steps = 120
        var lastPoint: CGPoint?

        for i in 0...steps {
            let fraction = Double(i) / Double(steps)
            // Longitude advances linearly (wrapping around globe)
            let lon = satellite.longitude + (fraction - 0.5) * 360.0 * (90.0 / orbitalPeriod)
            // Latitude oscillates sinusoidally
            let phase = 2.0 * .pi * fraction + asin(max(-1, min(1, satellite.latitude / inclination)))
            let lat = inclination * sin(phase)

            // Convert lat/lon to screen coordinates (equirectangular projection)
            let x = ((lon + 180.0).truncatingRemainder(dividingBy: 360.0)) / 360.0 * size.width
            let y = (90.0 - lat) / 180.0 * size.height
            let point = CGPoint(x: x, y: y)

            if let last = lastPoint {
                // Don't draw line if wrapping around the edge
                if abs(point.x - last.x) < size.width * 0.5 {
                    if path.isEmpty {
                        path.move(to: last)
                    }
                    path.addLine(to: point)
                } else {
                    // Break path at wrap
                    if !path.isEmpty {
                        context.stroke(path, with: .color(color), lineWidth: lineWidth)
                        path = Path()
                    }
                }
            }
            lastPoint = point
        }

        if !path.isEmpty {
            context.stroke(path, with: .color(color), lineWidth: lineWidth)
        }
    }

    /// Estimate orbital inclination from satellite group
    private func estimateInclination(_ sat: APIService.SatellitePosition) -> Double {
        switch sat.group {
        case "Starlink": return 53.0  // Most Starlink shells
        case "GPS": return 55.0       // GPS constellation
        case "Military": return 65.0  // Typical military LEO
        default: return 51.6          // ISS-like
        }
    }

    /// Estimate orbital period in minutes from altitude
    private func estimateOrbitalPeriod(altitude: Double) -> Double {
        let earthRadius = 6371.0 // km
        let r = earthRadius + altitude
        // T = 2π√(r³/μ), where μ = 398600.4 km³/s²
        let mu = 398600.4
        let periodSeconds = 2.0 * .pi * sqrt(pow(r, 3) / mu)
        return periodSeconds / 60.0 // Convert to minutes
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
            Text("Ground tracks show approximate orbital paths")
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
