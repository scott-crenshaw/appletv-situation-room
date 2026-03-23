import SwiftUI
import MapKit
import CoreLocation

/// Screen 10: Persian Gulf Command — conflict events, military flights, and satellite tracking
/// over the Middle East / Persian Gulf region. Dual-phase: tight Gulf → wide ME theater view.
struct GulfCommandScreenView: View {
    @ObservedObject var state: DashboardState
    @State private var isWidePhase = false

    var body: some View {
        HStack(spacing: 16) {
            // Left: Map (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    isWidePhase ? "MIDDLE EAST THEATER" : "PERSIAN GULF ZONE",
                    subtitle: "\(state.conflictEvents.count) EVENTS • \(state.gulfFlights.count) AIRCRAFT • \(state.militarySatellites.count) SATS"
                )
                GulfMapView(
                    conflictEvents: state.conflictEvents,
                    flights: state.gulfFlights,
                    satellites: state.militarySatellites,
                    isWidePhase: isWidePhase
                )
                .frame(maxHeight: .infinity)

                GulfStatsBar(
                    events: state.conflictEvents,
                    flights: state.gulfFlights,
                    satellites: state.militarySatellites
                )
            }
            .frame(maxWidth: .infinity)

            // Right: Intel sidebar
            VStack(spacing: 12) {
                sectionHeader("REGIONAL INTEL")
                GulfIntelSidebar(
                    events: state.conflictEvents,
                    flights: state.gulfFlights,
                    satellites: state.militarySatellites
                )
                .frame(maxHeight: .infinity)

                GulfLegend()
            }
            .frame(width: 580)
        }
        .padding(24)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { now in
            let elapsed = now.timeIntervalSince(state.screenStartedAt)
            let shouldBeWide = elapsed >= 30
            if shouldBeWide != isWidePhase {
                withAnimation(.easeInOut(duration: 2.0)) {
                    isWidePhase = shouldBeWide
                }
            }
        }
        .onChange(of: state.currentScreen) {
            isWidePhase = false
        }
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

// MARK: - Gulf Annotation Item (unified enum for all map markers)

enum GulfAnnotationItem: Identifiable {
    case conflict(ConflictEvent)
    case flight(APIService.FlightPosition)
    case satellite(APIService.SatellitePosition)
    case hotspot(Hotspot)

    var id: String {
        switch self {
        case .conflict(let e): return "c-\(e.id)"
        case .flight(let f): return "f-\(f.id)"
        case .satellite(let s): return "s-\(s.id)"
        case .hotspot(let h): return "h-\(h.id)"
        }
    }

    var coordinate: CLLocationCoordinate2D {
        switch self {
        case .conflict(let e): return CLLocationCoordinate2D(latitude: e.latitude ?? 0, longitude: e.longitude ?? 0)
        case .flight(let f): return CLLocationCoordinate2D(latitude: f.latitude, longitude: f.longitude)
        case .satellite(let s): return CLLocationCoordinate2D(latitude: s.latitude, longitude: s.longitude)
        case .hotspot(let h): return h.coordinate
        }
    }
}

// MARK: - Gulf Map View (old MapKit API — proven on physical Apple TV)

struct GulfMapView: View {
    let conflictEvents: [ConflictEvent]
    let flights: [APIService.FlightPosition]
    let satellites: [APIService.SatellitePosition]
    let isWidePhase: Bool

    @State private var mapRegion: MKCoordinateRegion

    // Phase 1: Tight on Persian Gulf
    static let gulfRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 26.5, longitude: 52),
        span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 18)
    )

    // Phase 2: Wide Middle East theater
    static let meRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 28, longitude: 42),
        span: MKCoordinateSpan(latitudeDelta: 35, longitudeDelta: 45)
    )

    init(conflictEvents: [ConflictEvent], flights: [APIService.FlightPosition], satellites: [APIService.SatellitePosition], isWidePhase: Bool) {
        self.conflictEvents = conflictEvents
        self.flights = flights
        self.satellites = satellites
        self.isWidePhase = isWidePhase
        _mapRegion = State(initialValue: GulfMapView.gulfRegion)
    }

    // Existing hotspots filtered to the Middle East
    private var meHotspots: [Hotspot] {
        sampleHotspots.filter { h in
            h.coordinate.latitude >= 10 && h.coordinate.latitude <= 42 &&
            h.coordinate.longitude >= 25 && h.coordinate.longitude <= 65
        }
    }

    // All annotations combined into one array
    private var allAnnotations: [GulfAnnotationItem] {
        var items: [GulfAnnotationItem] = []
        items.append(contentsOf: conflictEvents.filter(\.hasCoordinates).map { .conflict($0) })
        items.append(contentsOf: flights.map { .flight($0) })
        items.append(contentsOf: satellites.map { .satellite($0) })
        items.append(contentsOf: meHotspots.map { .hotspot($0) })
        return items
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Map(coordinateRegion: $mapRegion, annotationItems: allAnnotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    switch item {
                    case .conflict(let event):
                        ConflictEventMarker(event: event)
                    case .flight(let flight):
                        GulfAircraftDot(flight: flight, isWide: isWidePhase)
                    case .satellite(let sat):
                        SatelliteDot(satellite: sat)
                    case .hotspot(let hotspot):
                        MiniHotspotMarker(hotspot: hotspot)
                    }
                }
            }
            .mapStyle(.imagery)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
            .onChange(of: isWidePhase) { _, wide in
                withAnimation(.easeInOut(duration: 2.0)) {
                    mapRegion = wide ? GulfMapView.meRegion : GulfMapView.gulfRegion
                }
            }

            // Phase label
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                Text(isWidePhase ? "THEATER VIEW" : "GULF ZONE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.red.opacity(0.7))
            }
            .padding(8)
        }
    }
}

// MARK: - Conflict Event Marker (pulsing crosshair)

struct ConflictEventMarker: View {
    let event: ConflictEvent
    @State private var pulseScale: CGFloat = 0.8

    private var markerSize: CGFloat {
        switch event.intensity {
        case "CRITICAL": return 26
        case "ELEVATED": return 20
        case "MODERATE": return 16
        default: return 12
        }
    }

    private var markerColor: Color {
        switch event.intensity {
        case "CRITICAL": return .red
        case "ELEVATED": return .orange
        case "MODERATE": return .yellow
        default: return .yellow
        }
    }

    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .fill(markerColor.opacity(0.25))
                .frame(width: markerSize * 2.5, height: markerSize * 2.5)
                .scaleEffect(pulseScale)

            // Inner ring
            Circle()
                .stroke(markerColor.opacity(0.7), lineWidth: 1.5)
                .frame(width: markerSize * 1.5, height: markerSize * 1.5)

            // Core dot
            Circle()
                .fill(markerColor)
                .frame(width: markerSize * 0.6, height: markerSize * 0.6)
                .shadow(color: markerColor, radius: 5)

            // Crosshair for critical/elevated
            if event.intensity == "CRITICAL" || event.intensity == "ELEVATED" {
                Rectangle()
                    .fill(markerColor.opacity(0.5))
                    .frame(width: 1.5, height: markerSize * 2.5)
                Rectangle()
                    .fill(markerColor.opacity(0.5))
                    .frame(width: markerSize * 2.5, height: 1.5)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.3
            }
        }
    }
}

// MARK: - Gulf Aircraft Dot

struct GulfAircraftDot: View {
    let flight: APIService.FlightPosition
    var isWide: Bool = false

    var body: some View {
        Image(systemName: "arrowtriangle.up.fill")
            .font(.system(size: isWide ? 6 : (flight.isMilitary ? 14 : 9)))
            .foregroundColor(dotColor)
            .rotationEffect(.degrees(flight.heading))
            .shadow(color: dotColor, radius: flight.isMilitary ? 6 : 3)
    }

    private var dotColor: Color {
        if flight.isMilitary { return .red }
        if flight.altitude > 33000 { return .white }
        if flight.altitude > 16000 { return .cyan }
        return .green
    }
}

// MARK: - Satellite Dot (glowing)

struct SatelliteDot: View {
    let satellite: APIService.SatellitePosition
    @State private var glowOpacity: Double = 0.4

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(dotColor.opacity(glowOpacity))
                .frame(width: 20, height: 20)
            // Core
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
                .shadow(color: dotColor, radius: 4)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowOpacity = 0.8
            }
        }
    }

    private var dotColor: Color {
        satellite.group == "GPS" ? .green : .cyan
    }
}

// MARK: - Mini Hotspot Marker (compact for layered map)

struct MiniHotspotMarker: View {
    let hotspot: Hotspot

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: markerIcon)
                .font(.system(size: 14))
                .foregroundColor(markerColor)
                .shadow(color: markerColor, radius: 4)
            Text(hotspot.name)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 3)
                .lineLimit(1)
        }
    }

    private var markerColor: Color {
        switch hotspot.threatLevel {
        case .critical: return .red
        case .high: return .orange
        case .elevated: return .yellow
        case .monitoring: return .blue
        case .low: return .green
        }
    }

    private var markerIcon: String {
        switch hotspot.category {
        case .conflict: return "xmark.circle.fill"
        case .militaryBase: return "shield.fill"
        case .nuclearSite: return "bolt.circle.fill"
        case .hotspot: return "exclamationmark.triangle.fill"
        case .waterway: return "water.waves"
        }
    }
}

// MARK: - Gulf Intel Sidebar

struct GulfIntelSidebar: View {
    let events: [ConflictEvent]
    let flights: [APIService.FlightPosition]
    let satellites: [APIService.SatellitePosition]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                // Conflict Activity
                let geocoded = events.filter(\.hasCoordinates)
                sidebarSection("CONFLICT FEED (\(geocoded.count) LOCATED)") {
                    if events.isEmpty {
                        Text("NO CONFLICT DATA")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
                    } else {
                        ForEach(Array(events.prefix(12))) { event in
                            ConflictEventRow(event: event)
                        }
                    }
                }

                // Military Aircraft
                let milFlights = flights.filter(\.isMilitary)
                sidebarSection("MILITARY AIRCRAFT (\(milFlights.count))") {
                    if milFlights.isEmpty {
                        Text("NO MIL TRANSPONDERS ACTIVE")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
                    } else {
                        ForEach(milFlights.prefix(10)) { flight in
                            MilitaryFlightRow(flight: flight)
                        }
                    }
                }

                // Overhead Satellite Assets
                let milSats = satellites.filter { $0.group == "Military" }
                let gpsSats = satellites.filter { $0.group == "GPS" }
                sidebarSection("OVERHEAD ASSETS") {
                    HStack(spacing: 20) {
                        assetCount(label: "MILITARY", count: milSats.count, color: .cyan)
                        assetCount(label: "GPS", count: gpsSats.count, color: .green)
                        assetCount(label: "TOTAL", count: satellites.count, color: .white)
                    }

                    ForEach(milSats.prefix(8)) { sat in
                        HStack {
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 4, height: 4)
                            Text(sat.name)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                            Spacer()
                            Text(String(format: "%.0f km", sat.altitude))
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.6))
                        }
                    }
                }

                // Strategic Chokepoints
                sidebarSection("STRATEGIC CHOKEPOINTS") {
                    ChokepointStatusRow(name: "STRAIT OF HORMUZ", status: "MONITORED", icon: "water.waves", color: .orange)
                    ChokepointStatusRow(name: "BAB EL-MANDEB", status: "ELEVATED", icon: "exclamationmark.triangle.fill", color: .red)
                    ChokepointStatusRow(name: "SUEZ CANAL", status: "OPERATIONAL", icon: "water.waves", color: .green)
                }

                // Flight breakdown
                sidebarSection("AIRSPACE BREAKDOWN") {
                    let civil = flights.filter { !$0.isMilitary }
                    let highAlt = flights.filter { $0.altitude >= 33000 }
                    let lowAlt = flights.filter { $0.altitude < 16000 }
                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(flights.count)")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            Text("TOTAL")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        VStack(spacing: 2) {
                            Text("\(civil.count)")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                            Text("CIVIL")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        VStack(spacing: 2) {
                            Text("\(highAlt.count)")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.8))
                            Text(">FL330")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        VStack(spacing: 2) {
                            Text("\(lowAlt.count)")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                            Text("<FL160")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Color(red: 0.03, green: 0.02, blue: 0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.15), lineWidth: 0.5)
        )
    }

    private func sidebarSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .heavy, design: .monospaced))
                .foregroundColor(.red.opacity(0.7))
            content()
            Rectangle()
                .fill(Color.red.opacity(0.1))
                .frame(height: 1)
        }
    }

    private func assetCount(label: String, count: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Sidebar Row Components

struct ConflictEventRow: View {
    let event: ConflictEvent

    private var intensityColor: Color {
        switch event.intensity {
        case "CRITICAL": return .red
        case "ELEVATED": return .orange
        case "MODERATE": return .yellow
        default: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(intensityColor)
                .frame(width: 6, height: 6)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(event.source.uppercased())
                        .foregroundColor(.orange.opacity(0.8))
                    if let loc = event.matchedLocation {
                        Text(loc.uppercased())
                            .foregroundColor(.cyan.opacity(0.7))
                    }
                }
                .font(.system(size: 10, design: .monospaced))
            }
            Spacer()
        }
    }
}

struct MilitaryFlightRow: View {
    let flight: APIService.FlightPosition

    var body: some View {
        HStack(spacing: 8) {
            Text("M")
                .font(.system(size: 9, weight: .black, design: .monospaced))
                .foregroundColor(.black)
                .padding(.horizontal, 3)
                .background(Color.red)
                .cornerRadius(2)
            Text(flight.callsign.isEmpty ? String(flight.id.prefix(8)).uppercased() : flight.callsign)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.red)
                .lineLimit(1)
            Spacer()
            if !flight.aircraftType.isEmpty {
                Text(flight.aircraftType)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
            Text("FL\(Int(flight.altitude / 100))")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.7))
        }
    }
}

struct ChokepointStatusRow: View {
    let name: String
    let status: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(color)
            Text(name)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            Spacer()
            Text(status)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(color.opacity(0.15))
                .cornerRadius(3)
        }
    }
}

// MARK: - Gulf Stats Bar

struct GulfStatsBar: View {
    let events: [ConflictEvent]
    let flights: [APIService.FlightPosition]
    let satellites: [APIService.SatellitePosition]

    var body: some View {
        HStack(spacing: 24) {
            statItem("ARTICLES", value: "\(events.count)", color: .red)
            statItem("LOCATED", value: "\(events.filter(\.hasCoordinates).count)", color: .orange)
            statItem("AIRCRAFT", value: "\(flights.count)", color: .cyan)
            statItem("MIL AIR", value: "\(flights.filter(\.isMilitary).count)", color: .red)
            statItem("SATELLITES", value: "\(satellites.count)", color: .green)

            Spacer()

            Text("SOURCES: GDELT • ADSB.LOL • CELESTRAK")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.gray.opacity(0.5))
        }
        .font(.system(size: 12, weight: .medium, design: .monospaced))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private func statItem(_ label: String, value: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .foregroundColor(.gray)
            Text(value)
                .foregroundColor(color)
                .fontWeight(.bold)
        }
    }
}

// MARK: - Gulf Legend

struct GulfLegend: View {
    var body: some View {
        HStack(spacing: 16) {
            legendItem(color: .red, label: "CONFLICT")
            legendItem(color: .orange, label: "MODERATE")
            legendItem(color: .cyan, label: "MIL SAT")
            legendItem(color: .green, label: "GPS SAT")
            legendItem(color: .white, label: "CIVIL AIR")
            legendItem(color: .red, shape: "triangle", label: "MIL AIR")
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
        .cornerRadius(6)
    }

    private func legendItem(color: Color, shape: String = "circle", label: String) -> some View {
        HStack(spacing: 4) {
            if shape == "triangle" {
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 6))
                    .foregroundColor(color)
            } else {
                Circle().fill(color).frame(width: 6, height: 6)
            }
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
        }
    }
}
