import SwiftUI
import CoreLocation
import MapKit

/// Screen 9: Air Traffic Monitor — full-screen flight map + nearby aircraft table.
struct AirTrafficScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left: Flight map with real geography (2/3 width)
            VStack(spacing: 12) {
                sectionHeader("AIRSPACE TRAFFIC", subtitle: "\(state.flightPositions.count) AIRCRAFT TRACKED")
                FlightMapView(
                    flights: state.flightPositions,
                    userLocation: state.locationManager.userLocation
                )
                .frame(maxHeight: .infinity)

                FlightStatsBar(flights: state.flightPositions)
            }
            .frame(maxWidth: .infinity)

            // Right: Nearby aircraft table (1/3 width)
            VStack(spacing: 12) {
                sectionHeader("NEAREST AIRCRAFT", subtitle: state.locationManager.locationStatus)
                NearbyAircraftTable(flights: state.flightPositions)
                    .frame(maxHeight: .infinity)

                AltitudeLegend()
            }
            .frame(width: 640)
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

// MARK: - Flight Map (MapKit with aircraft overlay)

struct FlightMapView: View {
    let flights: [APIService.FlightPosition]
    let userLocation: CLLocation?

    // 250nm ≈ 463km — show a region slightly larger than the query radius
    private var mapRegion: MKCoordinateRegion {
        let center = userLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903)
        return MKCoordinateRegion(center: center, latitudinalMeters: 900_000, longitudinalMeters: 900_000)
    }

    var body: some View {
        Map(initialPosition: .region(mapRegion), interactionModes: []) {
            // User location marker
            if let loc = userLocation {
                Annotation("", coordinate: loc.coordinate, anchor: .center) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 24, height: 24)
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                    }
                }
            }

            // Aircraft — use lightweight annotations
            ForEach(flights) { flight in
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: flight.latitude, longitude: flight.longitude), anchor: .center) {
                    AircraftDot(flight: flight)
                }
            }
        }
        .mapStyle(.imagery(elevation: .flat))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyan.opacity(0.15), lineWidth: 0.5)
        )
        .overlay(alignment: .topLeading) {
            // Range ring legend
            Text("250 NM RADIUS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.5))
                .padding(8)
        }
    }
}

/// Lightweight aircraft dot for map annotation
struct AircraftDot: View {
    let flight: APIService.FlightPosition

    var body: some View {
        // Rotated triangle showing heading
        Image(systemName: "arrowtriangle.up.fill")
            .font(.system(size: flight.isMilitary ? 10 : 7))
            .foregroundColor(dotColor)
            .rotationEffect(.degrees(flight.heading))
            .shadow(color: dotColor.opacity(0.5), radius: 2)
    }

    private var dotColor: Color {
        if flight.isMilitary { return .red }
        if flight.altitude > 33000 { return .white }
        if flight.altitude > 16000 { return .cyan }
        return .green
    }
}

// MARK: - Nearby Aircraft Table

struct NearbyAircraftTable: View {
    let flights: [APIService.FlightPosition]

    private var sortedFlights: [APIService.FlightPosition] {
        flights
            .sorted { ($0.distanceNm ?? 9999) < ($1.distanceNm ?? 9999) }
            .prefix(20)
            .map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Table header
            HStack(spacing: 0) {
                Text("CALLSIGN")
                    .frame(width: 100, alignment: .leading)
                Text("REG")
                    .frame(width: 80, alignment: .leading)
                Text("TYPE")
                    .frame(width: 55, alignment: .leading)
                Text("DIST")
                    .frame(width: 65, alignment: .trailing)
                Text("ALT")
                    .frame(width: 65, alignment: .trailing)
                Text("SPD")
                    .frame(width: 60, alignment: .trailing)
                Text("HDG")
                    .frame(width: 55, alignment: .trailing)
            }
            .font(.system(size: 13, weight: .bold, design: .monospaced))
            .foregroundColor(.cyan.opacity(0.6))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.05))

            Rectangle().fill(Color.cyan.opacity(0.15)).frame(height: 1)

            if flights.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("NO AIRCRAFT DATA")
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                    Text("Waiting for feed...")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                    Spacer()
                }
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(sortedFlights.enumerated()), id: \.element.id) { index, flight in
                            NearbyFlightRow(flight: flight, isEven: index % 2 == 0)
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
    let isEven: Bool

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 4) {
                if flight.isMilitary {
                    Text("M")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 3)
                        .background(Color.red)
                        .cornerRadius(2)
                }
                Text(displayCallsign)
                    .foregroundColor(flight.isMilitary ? .red : .white)
            }
            .frame(width: 100, alignment: .leading)

            Text(flight.registration.isEmpty ? "—" : flight.registration)
                .frame(width: 80, alignment: .leading)
                .foregroundColor(.white.opacity(0.7))

            Text(flight.aircraftType.isEmpty ? "—" : flight.aircraftType)
                .frame(width: 55, alignment: .leading)
                .foregroundColor(.white.opacity(0.5))

            Text(formatDistance)
                .frame(width: 65, alignment: .trailing)
                .foregroundColor(distanceColor)

            Text(formatAltitude)
                .frame(width: 65, alignment: .trailing)
                .foregroundColor(altitudeColor)

            Text("\(Int(flight.velocity)) kt")
                .frame(width: 60, alignment: .trailing)
                .foregroundColor(.white.opacity(0.8))

            Text(formatHeading)
                .frame(width: 55, alignment: .trailing)
                .foregroundColor(.white.opacity(0.6))
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(isEven ? Color.white.opacity(0.02) : Color.clear)
    }

    private var displayCallsign: String {
        if !flight.callsign.isEmpty { return flight.callsign }
        if !flight.registration.isEmpty { return flight.registration }
        return flight.id.prefix(8).uppercased()
    }

    private var distanceColor: Color {
        guard let nm = flight.distanceNm else { return .white.opacity(0.8) }
        if nm < 25 { return .green }
        if nm < 100 { return .yellow }
        return .white.opacity(0.8)
    }

    private var altitudeColor: Color {
        if flight.altitude > 33000 { return .white }
        if flight.altitude > 16000 { return .cyan }
        return .green
    }

    private var formatDistance: String {
        guard let nm = flight.distanceNm else { return "—" }
        if nm < 10 { return String(format: "%.1fnm", nm) }
        return "\(Int(nm))nm"
    }

    private var formatAltitude: String {
        let alt = Int(flight.altitude)
        if alt >= 1000 { return "FL\(alt / 100)" }
        return "\(alt)ft"
    }

    private var formatHeading: String {
        let dirs = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        let idx = Int((flight.heading + 22.5).truncatingRemainder(dividingBy: 360) / 45)
        return "\(Int(flight.heading))°\(dirs[max(0, min(idx, 7))])"
    }
}

// MARK: - Flight Stats Bar

struct FlightStatsBar: View {
    let flights: [APIService.FlightPosition]

    var body: some View {
        HStack(spacing: 24) {
            statItem("TOTAL", value: "\(flights.count)")
            statItem("LOW (<FL160)", value: "\(flights.filter { $0.altitude < 16000 }.count)", color: .green)
            statItem("MID (FL160-330)", value: "\(flights.filter { $0.altitude >= 16000 && $0.altitude < 33000 }.count)", color: .cyan)
            statItem("HIGH (>FL330)", value: "\(flights.filter { $0.altitude >= 33000 }.count)", color: .white)

            let milCount = flights.filter(\.isMilitary).count
            if milCount > 0 {
                statItem("MIL", value: "\(milCount)", color: .red)
            }

            Spacer()

            let typeCounts = Dictionary(grouping: flights.filter { !$0.aircraftType.isEmpty }, by: \.aircraftType)
                .mapValues(\.count)
                .sorted { $0.value > $1.value }
                .prefix(5)
            ForEach(Array(typeCounts), id: \.key) { type, count in
                HStack(spacing: 4) {
                    Text(type)
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
            legendItem(color: .green, label: "<FL160")
            legendItem(color: .cyan, label: "FL160-330")
            legendItem(color: .white, label: ">FL330")
            legendItem(color: .red, label: "MILITARY")
            Spacer()
            Text("SOURCE: ADSB.LOL")
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
