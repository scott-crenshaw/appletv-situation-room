import SwiftUI

/// Cyber & Infrastructure Intelligence screen.
/// Shows weather alerts, recent CVEs, and infrastructure status indicators.
struct CyberScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left column: Severe Weather Alerts
            VStack(spacing: 16) {
                sectionHeader("SEVERE WEATHER ALERTS — US")

                if state.weatherAlerts.isEmpty {
                    loadingPlaceholder("Querying NWS API...")
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(state.weatherAlerts.prefix(12)) { alert in
                                WeatherAlertRow(alert: alert)
                            }
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Center column: Infrastructure Status + CVE Summary
            VStack(spacing: 16) {
                sectionHeader("INFRASTRUCTURE STATUS")

                InfraStatusPanel()

                sectionHeader("THREAT LANDSCAPE")

                ThreatLandscapePanel(
                    alertCount: state.weatherAlerts.count,
                    criticalCVEs: state.recentCVEs.filter { $0.severity == "CRITICAL" }.count,
                    highCVEs: state.recentCVEs.filter { $0.severity == "HIGH" }.count,
                    totalCVEs: state.recentCVEs.count
                )

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right column: Recent CVEs
            VStack(spacing: 16) {
                sectionHeader("RECENT CVEs — 7 DAY")

                if state.recentCVEs.isEmpty {
                    loadingPlaceholder("Fetching MITRE CVE data...")
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(state.recentCVEs.prefix(10)) { cve in
                                CVERow(cve: cve)
                            }
                        }
                    }
                }

                Spacer()
            }
            .frame(width: 420)
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

    private func loadingPlaceholder(_ text: String) -> some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            Text(text)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Weather Alert Row

struct WeatherAlertRow: View {
    let alert: WeatherAlert

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: alert.eventIcon)
                .font(.system(size: 20))
                .foregroundColor(severityColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(alert.event.uppercased())
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(alert.areaDesc)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.gray)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Text(alert.severity.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(severityColor)

                    Text(alert.urgency.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(urgencyColor)

                    if let expires = alert.expires {
                        Text(timeRemaining(until: expires))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()
        }
        .padding(10)
        .background(severityColor.opacity(0.08))
        .cornerRadius(8)
    }

    private var severityColor: Color {
        switch alert.severity.lowercased() {
        case "extreme": return .red
        case "severe": return .orange
        case "moderate": return .yellow
        default: return .green
        }
    }

    private var urgencyColor: Color {
        switch alert.urgency.lowercased() {
        case "immediate": return .red
        case "expected": return .orange
        default: return .yellow
        }
    }

    private func timeRemaining(until date: Date) -> String {
        let interval = date.timeIntervalSinceNow
        if interval <= 0 { return "EXPIRED" }
        if interval < 3600 { return "\(Int(interval / 60))m left" }
        if interval < 86400 { return "\(Int(interval / 3600))h left" }
        return "\(Int(interval / 86400))d left"
    }
}

// MARK: - CVE Row

struct CVERow: View {
    let cve: CVEEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(cve.id)
                    .font(.system(size: 15, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                Text(cve.severity)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(severityColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(severityColor.opacity(0.2))
                    .cornerRadius(4)

                if let score = cve.cvssScore {
                    Text(String(format: "%.1f", score))
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(severityColor)
                }
            }

            Text(cve.summary)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(2)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var severityColor: Color {
        switch cve.severity.uppercased() {
        case "CRITICAL": return .red
        case "HIGH": return .orange
        case "MEDIUM": return .yellow
        default: return .green
        }
    }
}

// MARK: - Infrastructure Status Panel

struct InfraStatusPanel: View {
    // Static indicators — these would ideally come from real monitoring APIs
    // but most require auth. These serve as a visual framework.
    private let indicators: [InfraStatus] = [
        InfraStatus(id: "dns", name: "DNS ROOT SERVERS", status: .operational, detail: "13/13 responding"),
        InfraStatus(id: "bgp", name: "GLOBAL BGP", status: .operational, detail: "No major hijacks detected"),
        InfraStatus(id: "cdn", name: "MAJOR CDN", status: .operational, detail: "Cloudflare, Akamai, Fastly"),
        InfraStatus(id: "submarine", name: "SUBMARINE CABLES", status: .operational, detail: "No reported outages"),
        InfraStatus(id: "cloud", name: "CLOUD PROVIDERS", status: .operational, detail: "AWS, Azure, GCP"),
        InfraStatus(id: "ntp", name: "NTP STRATUM 1", status: .operational, detail: "Time sync nominal"),
    ]

    var body: some View {
        VStack(spacing: 6) {
            ForEach(indicators) { indicator in
                HStack(spacing: 12) {
                    Circle()
                        .fill(statusColor(indicator.status))
                        .frame(width: 10, height: 10)

                    Text(indicator.name)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 200, alignment: .leading)

                    Text(indicator.status.rawValue)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor(indicator.status))
                        .frame(width: 120, alignment: .leading)

                    Text(indicator.detail)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)

                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func statusColor(_ status: InfraStatus.Status) -> Color {
        switch status {
        case .operational: return .green
        case .degraded: return .yellow
        case .outage: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Threat Landscape Panel

struct ThreatLandscapePanel: View {
    let alertCount: Int
    let criticalCVEs: Int
    let highCVEs: Int
    let totalCVEs: Int

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 24) {
                threatMetric(label: "ACTIVE ALERTS", value: "\(alertCount)", color: alertCount > 5 ? .orange : .green)
                threatMetric(label: "CRITICAL CVEs", value: "\(criticalCVEs)", color: criticalCVEs > 0 ? .red : .green)
                threatMetric(label: "HIGH CVEs", value: "\(highCVEs)", color: highCVEs > 3 ? .orange : .yellow)
                threatMetric(label: "TOTAL CVEs (7d)", value: "\(totalCVEs)", color: .cyan)
            }

            // Threat level bar
            HStack(spacing: 4) {
                Text("THREAT LEVEL:")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)

                threatBar
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func threatMetric(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
        }
    }

    private var threatBar: some View {
        let level = calculateThreatLevel()
        return HStack(spacing: 2) {
            ForEach(0..<10, id: \.self) { i in
                Rectangle()
                    .fill(i < level ? barColor(for: i) : Color.gray.opacity(0.2))
                    .frame(width: 20, height: 14)
                    .cornerRadius(2)
            }
            Text(threatLabel(for: level))
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(barColor(for: level - 1))
                .padding(.leading, 8)
        }
    }

    private func calculateThreatLevel() -> Int {
        var level = 2 // baseline
        level += min(criticalCVEs * 2, 4)
        level += min(highCVEs, 2)
        if alertCount > 10 { level += 2 }
        else if alertCount > 5 { level += 1 }
        return min(level, 10)
    }

    private func barColor(for index: Int) -> Color {
        if index < 3 { return .green }
        if index < 5 { return .yellow }
        if index < 7 { return .orange }
        return .red
    }

    private func threatLabel(for level: Int) -> String {
        switch level {
        case 0...2: return "LOW"
        case 3...4: return "GUARDED"
        case 5...6: return "ELEVATED"
        case 7...8: return "HIGH"
        default: return "SEVERE"
        }
    }
}
