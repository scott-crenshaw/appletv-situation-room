import SwiftUI
import MapKit

/// Screen 16: Space Launch Command — upcoming launches with countdown, map, and recent results.
struct SpaceLaunchScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left: Launch sites map
            VStack(spacing: 12) {
                sectionHeader(
                    "LAUNCH SITE TRACKING",
                    subtitle: "\(state.upcomingLaunches.count) UPCOMING — \(uniqueProviders) PROVIDERS"
                )
                LaunchSiteMapView(
                    upcoming: state.upcomingLaunches,
                    recent: state.recentLaunches
                )
                .frame(maxHeight: .infinity)
                LaunchStatsBar(
                    upcoming: state.upcomingLaunches,
                    recent: state.recentLaunches
                )
            }
            .frame(maxWidth: .infinity)

            // Right: Countdown + upcoming feed + recent results
            VStack(spacing: 12) {
                // Hero: Next launch whose NET is still in the future
                if let next = nextFutureLaunch {
                    NextLaunchCard(launch: next)
                }

                sectionHeader("UPCOMING LAUNCHES", subtitle: nil)
                UpcomingLaunchFeed(launches: upcomingAfterHero)
                    .frame(maxHeight: .infinity)

                sectionHeader("RECENT RESULTS", subtitle: nil)
                RecentResultsFeed(launches: state.recentLaunches)
                LaunchLegend()
            }
            .frame(width: 560)
        }
        .padding(24)
    }

    /// First upcoming launch whose NET is still in the future
    private var nextFutureLaunch: SpaceLaunch? {
        state.upcomingLaunches.first { $0.net > Date() }
    }

    /// Upcoming launches after the hero card (skip past-NET launches and the hero)
    private var upcomingAfterHero: [SpaceLaunch] {
        let futureLaunches = state.upcomingLaunches.filter { $0.net > Date() }
        return Array(futureLaunches.dropFirst().prefix(6))
    }

    private var uniqueProviders: Int {
        Set(state.upcomingLaunches.map(\.providerName)).count
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

// MARK: - Launch Site Map

struct LaunchSiteMapView: View {
    let upcoming: [SpaceLaunch]
    let recent: [SpaceLaunch]

    @State private var cameraPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        distance: 50_000_000
    ))

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            // Upcoming launch sites — pulsing cyan
            ForEach(upcoming) { launch in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: launch.latitude,
                    longitude: launch.longitude
                ), anchor: .center) {
                    LaunchSiteMarker(launch: launch, isUpcoming: true)
                }
            }
            // Recent launch sites — green/red result
            ForEach(recent) { launch in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: launch.latitude,
                    longitude: launch.longitude
                ), anchor: .center) {
                    LaunchSiteMarker(launch: launch, isUpcoming: false)
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

// MARK: - Launch Site Marker

struct LaunchSiteMarker: View {
    let launch: SpaceLaunch
    let isUpcoming: Bool
    @State private var isPulsing = false

    private var markerColor: Color {
        if !isUpcoming {
            return launch.status.isSuccessful ? .green : (launch.status.isFailed ? .red : .gray)
        }
        if launch.isVeryImminent { return .orange }
        if launch.isImminent { return .yellow }
        return .cyan
    }

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                // Pulsing ring for upcoming
                if isUpcoming {
                    Circle()
                        .stroke(markerColor.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 30, height: 30)
                        .scaleEffect(isPulsing ? 1.8 : 1.0)
                        .opacity(isPulsing ? 0.0 : 0.7)
                }
                // Glow
                Circle()
                    .fill(markerColor.opacity(0.25))
                    .frame(width: 18, height: 18)
                // Core icon
                Image(systemName: isUpcoming ? "arrow.up.circle.fill" : (launch.status.isSuccessful ? "checkmark.circle.fill" : "xmark.circle.fill"))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(markerColor)
            }
            // Label
            Text(launch.providerAbbrev)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(markerColor)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(Color.black.opacity(0.7))
                .cornerRadius(2)
        }
        .onAppear {
            if isUpcoming {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: false)) {
                    isPulsing = true
                }
            }
        }
    }
}

// MARK: - Next Launch Countdown Card (Hero)

struct NextLaunchCard: View {
    let launch: SpaceLaunch
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var statusColor: Color {
        switch launch.status {
        case .go: return .green
        case .tbc: return .orange
        case .tbd: return .yellow
        case .hold: return .red
        default: return .gray
        }
    }

    private var probabilityColor: Color {
        guard let p = launch.probability else { return .gray }
        if p >= 70 { return .green }
        if p >= 40 { return .yellow }
        return .red
    }

    var body: some View {
        VStack(spacing: 8) {
            // Mission header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(launch.rocketName.uppercased())
                        .font(.system(size: 18, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                    Text(launch.missionName.uppercased())
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                Spacer()
                // Status badge
                Text(launch.status.abbrev)
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .cornerRadius(4)
            }

            // Provider + Location
            HStack(spacing: 8) {
                Text(launch.providerAbbrev)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                Text("//")
                    .foregroundColor(.gray)
                Text(launch.locationName.uppercased())
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
                Spacer()
                if launch.webcastLive {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                        Text("LIVE")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
            }

            // Big countdown
            Text(launch.countdownString)
                .font(.system(size: 44, weight: .ultraLight, design: .monospaced))
                .foregroundColor(launch.isVeryImminent ? .orange : .white)
                .padding(.vertical, 4)

            // Probability bar + orbit
            HStack(spacing: 12) {
                if let prob = launch.probability {
                    HStack(spacing: 6) {
                        // Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 6)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(probabilityColor)
                                    .frame(width: geo.size.width * CGFloat(prob) / 100, height: 6)
                            }
                        }
                        .frame(height: 6)
                        Text("\(prob)%")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(probabilityColor)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
                if let orbit = launch.orbitName {
                    Text(orbit.uppercased())
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.1))
                        .cornerRadius(3)
                }
                if let weather = launch.weatherConcerns {
                    HStack(spacing: 3) {
                        Image(systemName: "cloud.bolt")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text(weather.prefix(30).uppercased())
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.yellow.opacity(0.8))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(statusColor.opacity(0.3), lineWidth: 1)
                )
        )
        .onReceive(timer) { now = $0 }
    }
}

// MARK: - Upcoming Launch Feed

struct UpcomingLaunchFeed: View {
    let launches: [SpaceLaunch]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 6) {
                ForEach(launches) { launch in
                    UpcomingLaunchRow(launch: launch)
                }
            }
        }
    }
}

struct UpcomingLaunchRow: View {
    let launch: SpaceLaunch

    private var statusColor: Color {
        switch launch.status {
        case .go: return .green
        case .tbc: return .orange
        case .tbd: return .yellow
        case .hold: return .red
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                // Rocket icon
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.cyan)
                Text(launch.rocketName.uppercased())
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("|")
                    .foregroundColor(.gray)
                Text(launch.missionName.uppercased())
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.9))
                    .lineLimit(1)
                Spacer()
                Text(launch.status.abbrev)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(3)
            }
            HStack {
                Text(launch.providerAbbrev)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Text("//")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                Text(launch.locationName.prefix(35).uppercased())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                Spacer()
                Text(launch.dateString)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
            // Mission type + orbit tags
            HStack(spacing: 6) {
                if let mType = launch.missionType {
                    Text(mType.uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(2)
                }
                if let orbit = launch.orbitName {
                    Text(orbit.uppercased())
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.6))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(Color.cyan.opacity(0.08))
                        .cornerRadius(2)
                }
                if let prob = launch.probability {
                    Text("\(prob)% GO")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(prob >= 70 ? .green : (prob >= 40 ? .yellow : .red))
                }
                Spacer()
                if launch.webcastLive {
                    HStack(spacing: 3) {
                        Circle().fill(Color.red).frame(width: 5, height: 5)
                        Text("LIVE")
                            .font(.system(size: 9, weight: .black, design: .monospaced))
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(launch.isImminent ? Color.orange.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Recent Results Feed

struct RecentResultsFeed: View {
    let launches: [SpaceLaunch]

    /// For previous launches: explicit failure = red, explicit success = green,
    /// anything else (Go/TBD/TBC with past NET) = likely succeeded, show green
    private func resultColor(_ launch: SpaceLaunch) -> Color {
        if launch.status.isFailed { return .red }
        return .green
    }

    private func resultIcon(_ launch: SpaceLaunch) -> String {
        if launch.status.isFailed { return "xmark.circle.fill" }
        return "checkmark.circle.fill"
    }

    private func resultLabel(_ launch: SpaceLaunch) -> String {
        if launch.status.isSuccessful { return "SUCCESS" }
        if launch.status.isFailed { return launch.status.abbrev }
        // Past launch with pre-launch status — API hasn't updated
        return "SUCCESS"
    }

    var body: some View {
        VStack(spacing: 4) {
            ForEach(launches) { launch in
                HStack(spacing: 8) {
                    Image(systemName: resultIcon(launch))
                        .font(.system(size: 13))
                        .foregroundColor(resultColor(launch))
                    Text(launch.rocketName.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    Text("|")
                        .foregroundColor(.gray)
                    Text(launch.missionName.uppercased())
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                    Spacer()
                    Text(resultLabel(launch))
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(resultColor(launch))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.03))
                .cornerRadius(4)
            }
        }
    }
}

// MARK: - Stats Bar

struct LaunchStatsBar: View {
    let upcoming: [SpaceLaunch]
    let recent: [SpaceLaunch]

    private var nextInDays: String {
        guard let next = upcoming.first else { return "--" }
        let days = Int(next.net.timeIntervalSinceNow / 86400)
        if days <= 0 { return "TODAY" }
        if days == 1 { return "1 DAY" }
        return "\(days) DAYS"
    }

    private var goCount: Int { upcoming.filter { $0.status == .go }.count }
    private var successRate: String {
        guard !recent.isEmpty else { return "--%" }
        // Previous launches: if not explicitly failed, treat as success
        let failures = recent.filter { $0.status.isFailed }.count
        let successes = recent.count - failures
        return "\(successes * 100 / recent.count)%"
    }
    private var uniquePads: Int { Set(upcoming.map(\.padName)).count }
    private var uniqueProviders: Int { Set(upcoming.map(\.providerName)).count }
    private var launchesThisWeek: Int {
        let weekEnd = Date().addingTimeInterval(7 * 86400)
        return upcoming.filter { $0.net < weekEnd }.count
    }

    var body: some View {
        HStack(spacing: 24) {
            statItem("NEXT", nextInDays, .cyan)
            statItem("GO STATUS", "\(goCount)", goCount > 0 ? .green : .gray)
            statItem("THIS WEEK", "\(launchesThisWeek)", .cyan)
            statItem("PROVIDERS", "\(uniqueProviders)", .cyan)
            statItem("PADS", "\(uniquePads)", .cyan)
            statItem("RECENT", successRate, .green)
            statItem("SOURCE", "LL2 API", .gray)
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

struct LaunchLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            legendItem("UPCOMING", .cyan)
            legendItem("IMMINENT", .orange)
            legendItem("SUCCESS", .green)
            legendItem("FAILURE", .red)
            legendItem("GO", .green)
            legendItem("TBD", .yellow)
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
