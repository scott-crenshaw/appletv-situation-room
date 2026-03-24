import SwiftUI

/// Natural Threats screen — earthquakes, severe weather, natural events.
/// All real-time data, no hardcoded static content.
struct ThreatScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left: Earthquake list + Seismic Radar
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
                            ForEach(state.earthquakes.prefix(12)) { quake in
                                EarthquakeRow(earthquake: quake)
                            }
                        }
                    }
                }

                // Seismic radar
                if !state.earthquakes.isEmpty {
                    sectionHeader("SEISMIC RADAR", count: nil)
                    RadarSweepView(earthquakes: state.earthquakes)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Center: Severe Weather Alerts (moved from Cyber screen)
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader("SEVERE WEATHER — US", count: state.weatherAlerts.count)

                if state.weatherAlerts.isEmpty {
                    Text("No active severe weather alerts")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
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

            // Right: Natural Events (moved from Space screen)
            VStack(alignment: .leading, spacing: 8) {
                sectionHeader("NATURAL EVENTS — ACTIVE", count: state.naturalEvents.count)

                if state.naturalEvents.isEmpty {
                    Text("No active natural events")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 8) {
                            ForEach(state.naturalEvents) { event in
                                NaturalEventRow(event: event)
                            }
                        }
                    }
                }

                Spacer()
            }
            .frame(width: 480)
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

    private var isRecent: Bool {
        Date().timeIntervalSince(earthquake.time) < 3600 // less than 1 hour
    }

    var body: some View {
        HStack(spacing: 12) {
            // Magnitude badge with ring indicator
            ZStack {
                if isRecent {
                    QuakeRingPulse(color: magnitudeColor)
                }
                Text(earthquake.formattedMagnitude)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 60)
                    .padding(.vertical, 6)
                    .background(magnitudeColor.opacity(0.8))
                    .cornerRadius(6)
            }

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

// MARK: - Quake Ring Pulse (animated ring for recent earthquakes)

struct QuakeRingPulse: View {
    let color: Color
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.8

    var body: some View {
        Circle()
            .stroke(color, lineWidth: 2)
            .frame(width: 70, height: 36)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    scale = 1.6
                    opacity = 0
                }
            }
    }
}

// MARK: - Radar Sweep Display

struct RadarSweepView: View {
    let earthquakes: [Earthquake]
    @State private var sweepAngle: Double = 0

    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 4

            // Background circles
            for r in stride(from: 0.25, through: 1.0, by: 0.25) {
                let circleRect = CGRect(
                    x: center.x - radius * r, y: center.y - radius * r,
                    width: radius * r * 2, height: radius * r * 2
                )
                context.stroke(Path(ellipseIn: circleRect), with: .color(.green.opacity(0.1)), lineWidth: 0.5)
            }

            // Crosshairs
            var hLine = Path()
            hLine.move(to: CGPoint(x: center.x - radius, y: center.y))
            hLine.addLine(to: CGPoint(x: center.x + radius, y: center.y))
            context.stroke(hLine, with: .color(.green.opacity(0.1)), lineWidth: 0.5)

            var vLine = Path()
            vLine.move(to: CGPoint(x: center.x, y: center.y - radius))
            vLine.addLine(to: CGPoint(x: center.x, y: center.y + radius))
            context.stroke(vLine, with: .color(.green.opacity(0.1)), lineWidth: 0.5)

            // Sweep arm with trail
            let sweepRad = sweepAngle * .pi / 180
            for i in 0..<30 {
                let trailAngle = sweepRad - Double(i) * 0.02
                let opacity = 0.3 * (1.0 - Double(i) / 30.0)
                var armPath = Path()
                armPath.move(to: center)
                armPath.addLine(to: CGPoint(
                    x: center.x + radius * cos(trailAngle),
                    y: center.y + radius * sin(trailAngle)
                ))
                context.stroke(armPath, with: .color(.green.opacity(opacity)), lineWidth: 1.5)
            }

            // Earthquake blips
            for quake in earthquakes.prefix(12) {
                // Map lat/lon to polar position (arbitrary but consistent mapping)
                let angle = (quake.longitude + 180) / 360 * 2 * .pi
                let dist = (90 - abs(quake.latitude)) / 90 * Double(radius) * 0.9

                let blipX = center.x + dist * cos(angle)
                let blipY = center.y + dist * sin(angle)

                // Blip brightness fades after sweep passes
                let angleDiff = sweepRad - angle
                let normalizedDiff = angleDiff.truncatingRemainder(dividingBy: 2 * .pi)
                let fadeAmount = normalizedDiff > 0 && normalizedDiff < .pi ? (1.0 - normalizedDiff / .pi) : 0.15

                let blipSize = max(3, quake.magnitude - 3) * 2
                let blipColor: Color = quake.magnitude >= 6 ? .red : quake.magnitude >= 5 ? .orange : .green

                let blipRect = CGRect(x: blipX - blipSize / 2, y: blipY - blipSize / 2, width: blipSize, height: blipSize)
                context.fill(Path(ellipseIn: blipRect), with: .color(blipColor.opacity(fadeAmount * 0.8)))

                // Glow
                let glowRect = CGRect(x: blipX - blipSize, y: blipY - blipSize, width: blipSize * 2, height: blipSize * 2)
                context.fill(Path(ellipseIn: glowRect), with: .color(blipColor.opacity(fadeAmount * 0.2)))
            }
        }
        .frame(height: 200)
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.15), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            sweepAngle += 1.2 // ~4 second rotation
            if sweepAngle >= 360 { sweepAngle -= 360 }
        }
    }
}
