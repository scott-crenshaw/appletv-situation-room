import SwiftUI
import CoreLocation

/// Screen 9: Air Traffic Monitor — full-screen flight map + nearby aircraft table.
struct AirTrafficScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left: Full flight map (2/3 width)
            VStack(spacing: 12) {
                sectionHeader("GLOBAL AIRSPACE TRAFFIC", subtitle: "\(state.flightPositions.count) AIRCRAFT TRACKED")
                GlobalFlightMapView(flights: state.flightPositions, userLocation: state.locationManager.userLocation)
                    .frame(maxHeight: .infinity)

                // Stats bar under map
                FlightStatsBar(flights: state.flightPositions)
            }
            .frame(maxWidth: .infinity)

            // Right: Nearby aircraft table (1/3 width)
            VStack(spacing: 12) {
                sectionHeader("NEAREST AIRCRAFT", subtitle: state.locationManager.locationStatus)
                NearbyAircraftTable(
                    flights: state.flightPositions,
                    userLocation: state.locationManager.userLocation
                )
                .frame(maxHeight: .infinity)

                // Altitude legend
                AltitudeLegend()
            }
            .frame(width: 620)
        }
        .padding(24)
    }

    private func sectionHeader(_ title: String, subtitle: String? = nil) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundColor(.gray)
            if let subtitle {
                Spacer()
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.7))
            }
            Spacer()
        }
    }
}

// MARK: - Global Flight Map (Canvas)

struct GlobalFlightMapView: View {
    let flights: [APIService.FlightPosition]
    let userLocation: CLLocation?

    var body: some View {
        Canvas { context, size in
            let bgRect = CGRect(origin: .zero, size: size)
            context.fill(Path(bgRect), with: .color(Color(red: 0.02, green: 0.03, blue: 0.06)))

            // Map projection: simple equirectangular, global
            let minLon = -180.0, maxLon = 180.0
            let minLat = -60.0, maxLat = 75.0

            // Draw grid lines
            drawGrid(context: context, size: size, minLon: minLon, maxLon: maxLon, minLat: minLat, maxLat: maxLat)

            // Draw user location
            if let loc = userLocation {
                let ux = (loc.coordinate.longitude - minLon) / (maxLon - minLon) * size.width
                let uy = (1 - (loc.coordinate.latitude - minLat) / (maxLat - minLat)) * size.height
                if ux >= 0 && ux <= size.width && uy >= 0 && uy <= size.height {
                    // Pulsing circle for user location
                    let outerRect = CGRect(x: ux - 8, y: uy - 8, width: 16, height: 16)
                    context.fill(Path(ellipseIn: outerRect), with: .color(.orange.opacity(0.2)))
                    let innerRect = CGRect(x: ux - 3, y: uy - 3, width: 6, height: 6)
                    context.fill(Path(ellipseIn: innerRect), with: .color(.orange))

                    // Label
                    context.draw(
                        Text("YOU")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange),
                        at: CGPoint(x: ux, y: uy - 14)
                    )
                }
            }

            // Plot aircraft
            for flight in flights {
                let x = (flight.longitude - minLon) / (maxLon - minLon) * size.width
                let y = (1 - (flight.latitude - minLat) / (maxLat - minLat)) * size.height
                guard x >= 0 && x <= size.width && y >= 0 && y <= size.height else { continue }

                let color = altitudeColor(flight.altitude)
                let dotSize: CGFloat = 2.0
                let dotRect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: dotRect), with: .color(color.opacity(0.8)))

                // Heading line
                let headingRad = flight.heading * .pi / 180
                let lineLen: CGFloat = 6
                var headingPath = Path()
                headingPath.move(to: CGPoint(x: x, y: y))
                headingPath.addLine(to: CGPoint(
                    x: x + lineLen * sin(headingRad),
                    y: y - lineLen * cos(headingRad)
                ))
                context.stroke(headingPath, with: .color(color.opacity(0.4)), lineWidth: 0.5)
            }
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyan.opacity(0.15), lineWidth: 0.5)
        )
    }

    private func drawGrid(context: GraphicsContext, size: CGSize, minLon: Double, maxLon: Double, minLat: Double, maxLat: Double) {
        let gridColor = Color.white.opacity(0.04)

        // Longitude lines every 30°
        for lon in stride(from: -180.0, through: 180.0, by: 30.0) {
            let x = (lon - minLon) / (maxLon - minLon) * size.width
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
        }

        // Latitude lines every 15°
        for lat in stride(from: -60.0, through: 75.0, by: 15.0) {
            let y = (1 - (lat - minLat) / (maxLat - minLat)) * size.height
            var path = Path()
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
        }

        // Equator slightly brighter
        let eqY = (1 - (0 - minLat) / (maxLat - minLat)) * size.height
        var eqPath = Path()
        eqPath.move(to: CGPoint(x: 0, y: eqY))
        eqPath.addLine(to: CGPoint(x: size.width, y: eqY))
        context.stroke(eqPath, with: .color(Color.white.opacity(0.08)), lineWidth: 0.5)
    }

    private func altitudeColor(_ altMeters: Double) -> Color {
        let altKm = altMeters / 1000
        if altKm > 10 { return .white }
        if altKm > 5 { return .cyan }
        return .green
    }
}

// MARK: - Nearby Aircraft Table

struct NearbyAircraftTable: View {
    let flights: [APIService.FlightPosition]
    let userLocation: CLLocation?

    private var nearbyFlights: [(flight: APIService.FlightPosition, distanceKm: Double)] {
        guard let loc = userLocation else { return [] }
        return flights
            .map { flight in
                let flightLoc = CLLocation(latitude: flight.latitude, longitude: flight.longitude)
                let dist = loc.distance(from: flightLoc) / 1000.0 // km
                return (flight, dist)
            }
            .sorted { $0.distanceKm < $1.distanceKm }
            .prefix(20)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                Text("CALLSIGN")
                    .frame(width: 110, alignment: .leading)
                Text("DIST")
                    .frame(width: 75, alignment: .trailing)
                Text("ALT")
                    .frame(width: 80, alignment: .trailing)
                Text("SPD")
                    .frame(width: 70, alignment: .trailing)
                Text("HDG")
                    .frame(width: 60, alignment: .trailing)
                Text("COUNTRY")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 12)
            }
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundColor(.cyan.opacity(0.6))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.05))

            // Divider
            Rectangle().fill(Color.cyan.opacity(0.15)).frame(height: 1)

            if userLocation == nil {
                VStack(spacing: 8) {
                    Spacer()
                    Text("AWAITING LOCATION FIX...")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.orange.opacity(0.6))
                    Text("Grant location permission to see nearby aircraft")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else if nearbyFlights.isEmpty {
                VStack {
                    Spacer()
                    Text("NO AIRCRAFT IN RANGE")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(nearbyFlights.enumerated()), id: \.element.flight.id) { index, item in
                            NearbyFlightRow(
                                flight: item.flight,
                                distanceKm: item.distanceKm,
                                isEven: index % 2 == 0
                            )
                        }
                    }
                }
            }
        }
        .background(Color(red: 0.03, green: 0.04, blue: 0.07))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyan.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - Individual Flight Row

struct NearbyFlightRow: View {
    let flight: APIService.FlightPosition
    let distanceKm: Double
    let isEven: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(flight.callsign.isEmpty ? flight.id.prefix(8).uppercased() : flight.callsign)
                .frame(width: 110, alignment: .leading)
                .foregroundColor(.white)

            Text(formatDistance(distanceKm))
                .frame(width: 75, alignment: .trailing)
                .foregroundColor(distanceColor)

            Text(formatAltitude(flight.altitude))
                .frame(width: 80, alignment: .trailing)
                .foregroundColor(altitudeColor)

            Text(formatSpeed(flight.velocity))
                .frame(width: 70, alignment: .trailing)
                .foregroundColor(.white.opacity(0.8))

            Text(formatHeading(flight.heading))
                .frame(width: 60, alignment: .trailing)
                .foregroundColor(.white.opacity(0.6))

            Text(flight.originCountry.prefix(12).uppercased())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 12)
                .foregroundColor(.cyan.opacity(0.7))
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(isEven ? Color.white.opacity(0.02) : Color.clear)
    }

    private var distanceColor: Color {
        if distanceKm < 50 { return .green }
        if distanceKm < 200 { return .yellow }
        return .white.opacity(0.8)
    }

    private var altitudeColor: Color {
        let altKm = flight.altitude / 1000
        if altKm > 10 { return .white }
        if altKm > 5 { return .cyan }
        return .green
    }

    private func formatDistance(_ km: Double) -> String {
        if km < 10 { return String(format: "%.1f km", km) }
        return "\(Int(km)) km"
    }

    private func formatAltitude(_ meters: Double) -> String {
        let feet = Int(meters * 3.28084)
        if feet >= 1000 {
            return "FL\(feet / 100)"
        }
        return "\(feet) ft"
    }

    private func formatSpeed(_ mps: Double) -> String {
        let knots = Int(mps * 1.94384)
        return "\(knots) kt"
    }

    private func formatHeading(_ deg: Double) -> String {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let idx = Int((deg + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return String(format: "%03.0f° %@", deg, dirs[max(0, min(idx, 7))])
    }
}

// MARK: - Flight Stats Bar

struct FlightStatsBar: View {
    let flights: [APIService.FlightPosition]

    var body: some View {
        HStack(spacing: 24) {
            statItem("TOTAL", value: "\(flights.count)")
            statItem("LOW (<5km)", value: "\(flights.filter { $0.altitude / 1000 < 5 }.count)", color: .green)
            statItem("MID (5-10km)", value: "\(flights.filter { $0.altitude / 1000 >= 5 && $0.altitude / 1000 < 10 }.count)", color: .cyan)
            statItem("HIGH (>10km)", value: "\(flights.filter { $0.altitude / 1000 >= 10 }.count)", color: .white)

            Spacer()

            // Top countries
            let countryCounts = Dictionary(grouping: flights, by: \.originCountry)
                .mapValues(\.count)
                .sorted { $0.value > $1.value }
                .prefix(5)
            ForEach(Array(countryCounts), id: \.key) { country, count in
                HStack(spacing: 4) {
                    Text(country.prefix(10).uppercased())
                        .foregroundColor(.cyan.opacity(0.7))
                    Text("\(count)")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private func statItem(_ label: String, value: String, color: Color = .white) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundColor(.gray)
            Text(value)
                .foregroundColor(color)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Altitude Legend

struct AltitudeLegend: View {
    var body: some View {
        HStack(spacing: 20) {
            legendItem(color: .green, label: "<5 km / FL160")
            legendItem(color: .cyan, label: "5-10 km / FL160-330")
            legendItem(color: .white, label: ">10 km / FL330+")
            Spacer()
            Text("SOURCE: OPENSKY NETWORK")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
        .cornerRadius(6)
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}
