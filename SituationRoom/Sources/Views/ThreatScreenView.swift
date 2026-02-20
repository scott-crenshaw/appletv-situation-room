import SwiftUI

/// Threat Assessment screen — earthquakes, theater posture, instability.
struct ThreatScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left: Earthquake list
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader("EARTHQUAKES (24H, M4.5+)", count: state.earthquakes.count)

                if state.earthquakes.isEmpty {
                    Text("No significant earthquakes in the last 24 hours")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(state.earthquakes.prefix(15)) { quake in
                                EarthquakeRow(earthquake: quake)
                            }
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right: Theater posture + hotspot summary
            VStack(alignment: .leading, spacing: 16) {
                sectionHeader("STRATEGIC THEATER POSTURE", count: nil)

                // Static theater posture cards (no free API available for real-time theater data)
                TheaterCard(name: "Iran Theater", status: "CRITICAL", airActivity: 2, seaActivity: 29, trend: "stable")
                TheaterCard(name: "Baltic Theater", status: "CRITICAL", airActivity: 18, seaActivity: 148, trend: "stable")
                TheaterCard(name: "Taiwan Strait", status: "ELEVATED", airActivity: 8, seaActivity: 42, trend: "increasing")
                TheaterCard(name: "Korean Peninsula", status: "MONITORING", airActivity: 4, seaActivity: 12, trend: "stable")

                sectionHeader("ACTIVE CONFLICTS", count: nil)

                // Conflict summary from hotspots
                VStack(spacing: 6) {
                    ConflictRow(name: "Ukraine-Russia", status: "ACTIVE", intensity: "High")
                    ConflictRow(name: "Gaza", status: "ACTIVE", intensity: "Critical")
                    ConflictRow(name: "Sudan", status: "ACTIVE", intensity: "High")
                    ConflictRow(name: "Myanmar", status: "ACTIVE", intensity: "High")
                    ConflictRow(name: "Sahel Region", status: "ACTIVE", intensity: "Elevated")
                }

                Spacer()
            }
            .frame(width: 500)
        }
        .padding(24)
    }

    private func sectionHeader(_ title: String, count: Int?) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                .foregroundColor(.gray)
            if let count {
                Text("\(count)")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)
            }
            Spacer()
        }
    }
}

// MARK: - Earthquake Row

struct EarthquakeRow: View {
    let earthquake: Earthquake

    var body: some View {
        HStack(spacing: 12) {
            // Magnitude badge
            Text(earthquake.formattedMagnitude)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 60)
                .padding(.vertical, 6)
                .background(magnitudeColor.opacity(0.8))
                .cornerRadius(6)

            // Location + depth
            VStack(alignment: .leading, spacing: 2) {
                Text(earthquake.place)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("Depth: \(String(format: "%.0f", earthquake.depth)) km")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            // Time ago
            Text(timeAgo(earthquake.time))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private var magnitudeColor: Color {
        switch earthquake.magnitude {
        case ..<5.0: return .yellow
        case ..<6.0: return .orange
        case ..<7.0: return .red
        default: return .red
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        return "\(Int(interval / 3600))h ago"
    }
}

// MARK: - Theater Posture Card

struct TheaterCard: View {
    let name: String
    let status: String
    let airActivity: Int
    let seaActivity: Int
    let trend: String

    private var statusColor: Color {
        switch status {
        case "CRITICAL": return .red
        case "HIGH": return .orange
        case "ELEVATED": return .yellow
        case "MONITORING": return .blue
        default: return .gray
        }
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Text(status)
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundColor(statusColor)
                }

                HStack(spacing: 16) {
                    Label("\(airActivity)", systemImage: "airplane")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.cyan)
                    Label("\(seaActivity)", systemImage: "ferry.fill")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.blue)
                    HStack(spacing: 4) {
                        Image(systemName: trend == "increasing" ? "arrow.up.right" : "arrow.right")
                        Text(trend)
                    }
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(trend == "increasing" ? .orange : .gray)
                }
            }
        }
        .padding(12)
        .background(statusColor.opacity(0.08))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

// MARK: - Conflict Row

struct ConflictRow: View {
    let name: String
    let status: String
    let intensity: String

    private var intensityColor: Color {
        switch intensity {
        case "Critical": return .red
        case "High": return .orange
        case "Elevated": return .yellow
        default: return .gray
        }
    }

    var body: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(intensityColor)
                .font(.system(size: 14))
            Text(name)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
            Spacer()
            Text(intensity.uppercased())
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(intensityColor)
        }
        .padding(.vertical, 4)
    }
}
