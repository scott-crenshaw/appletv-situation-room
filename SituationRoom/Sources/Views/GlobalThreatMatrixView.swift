import SwiftUI

/// Global Threat Matrix screen.
/// Combines multi-hazard data, DEFCON estimator, conflict tracker, and global risk assessment.
struct GlobalThreatMatrixView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left column: DEFCON Estimator + Multi-Hazard Events
            VStack(spacing: 16) {
                DEFCONEstimatorPanel(state: state)

                sectionHeader("MULTI-HAZARD EVENTS")

                ScrollView {
                    VStack(spacing: 6) {
                        // Earthquakes
                        ForEach(state.earthquakes.prefix(5)) { quake in
                            HazardRow(
                                icon: "waveform.path.ecg",
                                title: "M\(String(format: "%.1f", quake.magnitude)) — \(quake.place)",
                                category: "EARTHQUAKE",
                                severity: quake.magnitude >= 6 ? "SEVERE" : "MODERATE",
                                time: quake.time
                            )
                        }
                        // Natural events
                        ForEach(state.naturalEvents.prefix(5)) { event in
                            HazardRow(
                                icon: event.categoryIcon,
                                title: event.title,
                                category: event.category.uppercased(),
                                severity: "ACTIVE",
                                time: event.date
                            )
                        }
                        // Weather alerts
                        ForEach(state.weatherAlerts.prefix(3)) { alert in
                            HazardRow(
                                icon: alert.eventIcon,
                                title: alert.event,
                                category: "WEATHER",
                                severity: alert.severity.uppercased(),
                                time: alert.onset
                            )
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Center column: Global Risk Summary
            VStack(spacing: 16) {
                sectionHeader("GLOBAL RISK SUMMARY")

                GlobalRiskPanel(state: state)

                sectionHeader("CONFLICT TRACKER")

                ScrollView {
                    VStack(spacing: 8) {
                        ConflictDetailRow(name: "Ukraine-Russia", region: "Eastern Europe", startYear: "2022", intensity: .critical,
                                         details: "Full-scale invasion. Active frontline combat across multiple oblasts.")
                        ConflictDetailRow(name: "Gaza", region: "Middle East", startYear: "2023", intensity: .critical,
                                         details: "Israeli military operations ongoing. Severe humanitarian crisis.")
                        ConflictDetailRow(name: "Sudan", region: "East Africa", startYear: "2023", intensity: .high,
                                         details: "RSF vs SAF civil war. Widespread displacement and famine risk.")
                        ConflictDetailRow(name: "Myanmar", region: "Southeast Asia", startYear: "2021", intensity: .high,
                                         details: "Military junta vs resistance forces. Territorial fragmentation.")
                        ConflictDetailRow(name: "Sahel Region", region: "West Africa", startYear: "2012", intensity: .elevated,
                                         details: "Jihadist insurgency across Mali, Burkina Faso, Niger.")
                        ConflictDetailRow(name: "Ethiopia (Amhara)", region: "East Africa", startYear: "2023", intensity: .elevated,
                                         details: "Fano militia insurgency following Tigray ceasefire.")
                        ConflictDetailRow(name: "DRC (East)", region: "Central Africa", startYear: "2022", intensity: .elevated,
                                         details: "M23 resurgence. Regional proxy dynamics with Rwanda.")
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right column: Doomsday Clock + Key Indicators
            VStack(spacing: 16) {
                sectionHeader("DOOMSDAY CLOCK")
                DoomsdayClockView()

                sectionHeader("KEY RISK INDICATORS")

                KeyRiskIndicatorsPanel(state: state)

                sectionHeader("THREAT FEEDS")

                ThreatFeedPanel(headlines: state.headlines)

                // Flight tracking density map
                if !state.flightPositions.isEmpty {
                    sectionHeader("AIRSPACE TRAFFIC")
                    FlightTrackerView(flights: state.flightPositions)
                }

                Spacer()
            }
            .frame(width: 380)
        }
        .padding(24)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
        }
    }
}

// MARK: - DEFCON Estimator Panel

struct DEFCONEstimatorPanel: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 20) {
            // DEFCON level display
            VStack(spacing: 4) {
                Text("DEFCON")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                Text("\(state.defconLevel)")
                    .font(.system(size: 56, weight: .heavy, design: .monospaced))
                    .foregroundColor(defconColor)
                Text(defconLabel)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(defconColor)
            }
            .frame(width: 120)

            // DEFCON level bar
            VStack(alignment: .leading, spacing: 8) {
                ForEach(1...5, id: \.self) { level in
                    HStack(spacing: 8) {
                        Text("\(level)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(level == state.defconLevel ? .white : .gray)
                            .frame(width: 20)

                        Rectangle()
                            .fill(level == state.defconLevel ? defconColorForLevel(level) : defconColorForLevel(level).opacity(0.2))
                            .frame(height: 12)
                            .cornerRadius(2)

                        Text(labelForLevel(level))
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(level == state.defconLevel ? .white : .gray.opacity(0.5))
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(defconColor.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(defconColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private var defconColor: Color { defconColorForLevel(state.defconLevel) }

    private func defconColorForLevel(_ level: Int) -> Color {
        switch level {
        case 1: return .red
        case 2: return .red
        case 3: return .orange
        case 4: return .yellow
        case 5: return .green
        default: return .gray
        }
    }

    private var defconLabel: String { labelForLevel(state.defconLevel) }

    private func labelForLevel(_ level: Int) -> String {
        switch level {
        case 1: return "NUCLEAR WAR IMMINENT"
        case 2: return "NEXT STEP TO NUCLEAR"
        case 3: return "INCREASE READINESS"
        case 4: return "ABOVE NORMAL READINESS"
        case 5: return "LOWEST READINESS"
        default: return "UNKNOWN"
        }
    }
}

// MARK: - Hazard Row

struct HazardRow: View {
    let icon: String
    let title: String
    let category: String
    let severity: String
    let time: Date?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(severityColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(category)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(severityColor)

                    if let time {
                        Text(timeAgo(from: time))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()

            Text(severity)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(severityColor)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(severityColor.opacity(0.2))
                .cornerRadius(3)
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private var severityColor: Color {
        switch severity.uppercased() {
        case "EXTREME", "CRITICAL", "SEVERE": return .red
        case "HIGH", "ACTIVE": return .orange
        case "MODERATE", "ELEVATED": return .yellow
        default: return .green
        }
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Global Risk Panel

struct GlobalRiskPanel: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        let riskMetrics = calculateRisks()

        VStack(spacing: 12) {
            HStack(spacing: 16) {
                RiskGauge(label: "GEOPOLITICAL", value: riskMetrics.geopolitical, maxValue: 10)
                RiskGauge(label: "NATURAL", value: riskMetrics.natural, maxValue: 10)
                RiskGauge(label: "ECONOMIC", value: riskMetrics.economic, maxValue: 10)
                RiskGauge(label: "CYBER", value: riskMetrics.cyber, maxValue: 10)
            }

            // Overall composite
            HStack {
                Text("COMPOSITE RISK:")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)

                let composite = (riskMetrics.geopolitical + riskMetrics.natural + riskMetrics.economic + riskMetrics.cyber) / 4.0
                Text(String(format: "%.1f / 10", composite))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(riskColor(composite))

                Spacer()

                Text(riskLabel(composite))
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(riskColor(composite))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(riskColor(composite).opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private struct RiskMetrics {
        let geopolitical: Double
        let natural: Double
        let economic: Double
        let cyber: Double
    }

    private func calculateRisks() -> RiskMetrics {
        // Geopolitical: based on active conflicts + DEFCON
        let geopolitical = min(Double(11 - state.defconLevel) * 1.5 + 2, 10)

        // Natural: based on earthquake count and severity + natural events
        let maxMag = state.earthquakes.first?.magnitude ?? 0
        var natural = min(Double(state.earthquakes.count) * 0.3 + Double(state.naturalEvents.count) * 0.2, 8)
        if maxMag >= 7 { natural = min(natural + 3, 10) }
        else if maxMag >= 6 { natural = min(natural + 1.5, 10) }

        // Economic: based on VIX and market performance
        let vix = state.marketQuotes.first(where: { $0.symbol == "^VIX" })?.price ?? 20
        var economic = min(vix / 5.0, 10)
        if let fg = state.fearGreed, fg.value < 25 { economic = min(economic + 2, 10) }

        // Cyber: based on CVE severity
        let criticalCVEs = state.recentCVEs.filter { $0.severity == "CRITICAL" }.count
        let cyber = min(Double(criticalCVEs) * 1.5 + Double(state.recentCVEs.count) * 0.2 + 2, 10)

        return RiskMetrics(geopolitical: geopolitical, natural: natural, economic: economic, cyber: cyber)
    }

    private func riskColor(_ value: Double) -> Color {
        if value >= 7 { return .red }
        if value >= 5 { return .orange }
        if value >= 3 { return .yellow }
        return .green
    }

    private func riskLabel(_ value: Double) -> String {
        if value >= 8 { return "CRITICAL" }
        if value >= 6 { return "HIGH" }
        if value >= 4 { return "ELEVATED" }
        if value >= 2 { return "GUARDED" }
        return "LOW"
    }
}

struct RiskGauge: View {
    let label: String
    let value: Double
    let maxValue: Double

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: value / maxValue)
                    .stroke(gaugeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                Text(String(format: "%.0f", value))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(gaugeColor)
            }
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
        }
    }

    private var gaugeColor: Color {
        if value >= 7 { return .red }
        if value >= 5 { return .orange }
        if value >= 3 { return .yellow }
        return .green
    }
}

// MARK: - Conflict Detail Row

struct ConflictDetailRow: View {
    let name: String
    let region: String
    let startYear: String
    let intensity: Intensity
    let details: String

    enum Intensity {
        case critical, high, elevated, low

        var color: Color {
            switch self {
            case .critical: return .red
            case .high: return .orange
            case .elevated: return .yellow
            case .low: return .green
            }
        }

        var label: String {
            switch self {
            case .critical: return "CRITICAL"
            case .high: return "HIGH"
            case .elevated: return "ELEVATED"
            case .low: return "LOW"
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(intensity.color)
                    .frame(width: 8, height: 8)
                Text(name)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Text(intensity.label)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(intensity.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(intensity.color.opacity(0.2))
                    .cornerRadius(3)
            }
            HStack(spacing: 8) {
                Text(region)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.cyan)
                Text("Since \(startYear)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }
            Text(details)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray.opacity(0.8))
                .lineLimit(2)
        }
        .padding(10)
        .background(intensity.color.opacity(0.04))
        .cornerRadius(8)
    }
}

// MARK: - Key Risk Indicators Panel

struct KeyRiskIndicatorsPanel: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        VStack(spacing: 8) {
            indicatorRow("VIX (Fear Index)", value: vixValue, color: vixColor)
            indicatorRow("Fear & Greed", value: fgValue, color: fgColor)
            indicatorRow("Active Quakes (24h)", value: "\(state.earthquakes.count)", color: state.earthquakes.count > 10 ? .orange : .green)
            indicatorRow("Weather Alerts (US)", value: "\(state.weatherAlerts.count)", color: state.weatherAlerts.count > 10 ? .orange : .green)
            indicatorRow("Critical CVEs (7d)", value: "\(state.recentCVEs.filter { $0.severity == "CRITICAL" }.count)", color: state.recentCVEs.filter { $0.severity == "CRITICAL" }.count > 0 ? .red : .green)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private func indicatorRow(_ label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }

    private var vixValue: String {
        guard let vix = state.marketQuotes.first(where: { $0.symbol == "^VIX" }) else { return "—" }
        return String(format: "%.2f", vix.price)
    }

    private var vixColor: Color {
        guard let vix = state.marketQuotes.first(where: { $0.symbol == "^VIX" }) else { return .gray }
        if vix.price >= 30 { return .red }
        if vix.price >= 20 { return .orange }
        return .green
    }

    private var fgValue: String {
        guard let fg = state.fearGreed else { return "—" }
        return "\(fg.value) (\(fg.classification))"
    }

    private var fgColor: Color {
        guard let fg = state.fearGreed else { return .gray }
        if fg.value < 25 { return .red }
        if fg.value < 45 { return .orange }
        if fg.value < 55 { return .yellow }
        return .green
    }
}

// MARK: - Threat Feed Panel

struct ThreatFeedPanel: View {
    let headlines: [NewsItem]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(headlines.filter { $0.category == .geopolitics || $0.category == .crisis || $0.category == .military }.prefix(6)) { item in
                HStack(spacing: 8) {
                    Text("■")
                        .font(.system(size: 8))
                        .foregroundColor(.red)
                    Text(item.title)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Flight Tracker View

struct FlightTrackerView: View {
    let flights: [APIService.FlightPosition]

    var body: some View {
        Canvas { context, size in
            // Map bounds: lon -130..50, lat 20..55 (N America + Europe)
            let minLon = -130.0, maxLon = 50.0
            let minLat = 20.0, maxLat = 55.0

            // Draw coastline approximation (just a border)
            let borderRect = CGRect(x: 2, y: 2, width: size.width - 4, height: size.height - 4)
            context.stroke(Path(roundedRect: borderRect, cornerRadius: 4), with: .color(.white.opacity(0.05)), lineWidth: 0.5)

            // Plot aircraft
            for flight in flights {
                let x = (flight.longitude - minLon) / (maxLon - minLon) * size.width
                let y = (1 - (flight.latitude - minLat) / (maxLat - minLat)) * size.height

                guard x >= 0 && x <= size.width && y >= 0 && y <= size.height else { continue }

                // Altitude-based color: low = green, cruise = cyan, high = white
                let altKm = flight.altitude / 1000
                let color: Color = altKm > 10 ? .white : altKm > 5 ? .cyan : .green

                // Tiny dot
                let dotSize: CGFloat = 1.5
                let dotRect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: dotRect), with: .color(color.opacity(0.7)))

                // Heading indicator (tiny line)
                let headingRad = flight.heading * .pi / 180
                let lineLen: CGFloat = 4
                var headingPath = Path()
                headingPath.move(to: CGPoint(x: x, y: y))
                headingPath.addLine(to: CGPoint(
                    x: x + lineLen * sin(headingRad),
                    y: y - lineLen * cos(headingRad)
                ))
                context.stroke(headingPath, with: .color(color.opacity(0.3)), lineWidth: 0.5)
            }

            // Count label
            context.draw(
                Text("\(flights.count) AIRCRAFT")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.6)),
                at: CGPoint(x: size.width / 2, y: size.height - 8)
            )
        }
        .frame(height: 120)
        .background(Color(red: 0.02, green: 0.03, blue: 0.06))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyan.opacity(0.1), lineWidth: 0.5)
        )
    }
}
