import SwiftUI

/// Space & Geophysical Intelligence screen.
/// Shows solar weather, ISS position, asteroid approaches, and natural events.
struct SpaceScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left column: Space Weather + ISS
            VStack(spacing: 16) {
                sectionHeader("SOLAR WEATHER")

                if let sw = state.spaceWeather {
                    SpaceWeatherPanel(weather: sw)
                } else {
                    loadingPlaceholder("Connecting to NOAA SWPC...")
                }

                sectionHeader("ISS TRACKER")

                if let iss = state.issPosition {
                    ISSPanel(position: iss)
                } else {
                    loadingPlaceholder("Locating ISS...")
                }

                // Aurora oval visualization
                if !state.auroraData.isEmpty {
                    sectionHeader("AURORA PROBABILITY")
                    AuroraOvalView(data: state.auroraData, kpIndex: state.spaceWeather?.kpIndex ?? 0)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Center column: Natural Events
            VStack(spacing: 16) {
                sectionHeader("NATURAL EVENTS — ACTIVE")

                if state.naturalEvents.isEmpty {
                    loadingPlaceholder("Fetching NASA EONET...")
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(state.naturalEvents) { event in
                                NaturalEventRow(event: event)
                            }
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right column: Asteroid Approaches
            VStack(spacing: 16) {
                sectionHeader("NEAR-EARTH OBJECTS")

                if state.asteroidApproaches.isEmpty {
                    loadingPlaceholder("Querying JPL SBDB...")
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(state.asteroidApproaches) { asteroid in
                                AsteroidRow(asteroid: asteroid)
                            }
                        }
                    }
                }

                // Doomsday Clock
                sectionHeader("DOOMSDAY CLOCK")
                DoomsdayClockView()

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

// MARK: - Space Weather Panel

struct SpaceWeatherPanel: View {
    let weather: SpaceWeather

    var body: some View {
        VStack(spacing: 16) {
            // Kp Index — large gauge
            HStack(spacing: 24) {
                // Kp gauge
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        Circle()
                            .trim(from: 0, to: weather.kpIndex / 9.0)
                            .stroke(kpColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 0) {
                            Text(String(format: "%.0f", weather.kpIndex))
                                .font(.system(size: 36, weight: .bold, design: .monospaced))
                                .foregroundColor(kpColor)
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.8), value: weather.kpIndex)
                            Text("Kp")
                                .font(.system(size: 14, weight: .bold, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                    }
                    Text(weather.stormLevel)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(kpColor)
                }

                // Solar wind metrics
                VStack(alignment: .leading, spacing: 12) {
                    metricRow(label: "SOLAR WIND", value: String(format: "%.0f km/s", weather.solarWindSpeed), color: windColor)
                    metricRow(label: "DENSITY", value: String(format: "%.1f p/cm³", weather.solarWindDensity), color: .cyan)
                    metricRow(label: "Bz", value: String(format: "%.1f nT", weather.bzComponent), color: weather.bzComponent < 0 ? .red : .green)
                    metricRow(label: "G-SCALE", value: weather.kpCategory, color: kpColor)
                }

                Spacer()
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private func metricRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .foregroundColor(.gray)
                .frame(width: 120, alignment: .leading)
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.8), value: value)
        }
    }

    private var kpColor: Color {
        switch weather.kpIndex {
        case ..<4: return .green
        case ..<5: return .yellow
        case ..<7: return .orange
        default: return .red
        }
    }

    private var windColor: Color {
        switch weather.solarWindSpeed {
        case ..<400: return .green
        case ..<600: return .yellow
        case ..<800: return .orange
        default: return .red
        }
    }
}

// MARK: - ISS Panel

struct ISSPanel: View {
    let position: ISSPosition

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "airplane")
                .font(.system(size: 30))
                .foregroundColor(.cyan)
                .rotationEffect(.degrees(-45))

            VStack(alignment: .leading, spacing: 6) {
                Text("INTERNATIONAL SPACE STATION")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)

                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("LAT")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(String(format: "%.4f°", position.latitude))
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.8), value: position.latitude)
                    }
                    VStack(alignment: .leading) {
                        Text("LON")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(String(format: "%.4f°", position.longitude))
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.8), value: position.longitude)
                    }
                    VStack(alignment: .leading) {
                        Text("ALT")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                        Text("~408 km")
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }

                Text("Velocity: ~27,600 km/h  •  Orbit: 92 min")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Natural Event Row

struct NaturalEventRow: View {
    let event: NaturalEvent

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: event.categoryIcon)
                .font(.system(size: 20))
                .foregroundColor(categoryColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(event.title)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Text(event.category.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(categoryColor)

                    if let date = event.date {
                        Text(timeAgo(from: date))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                    }

                    if let lat = event.latitude, let lon = event.longitude {
                        Text(String(format: "%.1f°, %.1f°", lat, lon))
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var categoryColor: Color {
        switch event.category.lowercased() {
        case let c where c.contains("fire") || c.contains("wildfire"): return .orange
        case let c where c.contains("volcano"): return .red
        case let c where c.contains("storm") || c.contains("cyclone"): return .purple
        case let c where c.contains("flood"): return .blue
        case let c where c.contains("ice"): return .cyan
        default: return .yellow
        }
    }

    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Asteroid Row

struct AsteroidRow: View {
    let asteroid: AsteroidApproach

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(threatColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 3) {
                Text(asteroid.name)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                HStack(spacing: 12) {
                    Text(asteroid.closeApproachDate)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.gray)

                    Text(String(format: "%.1f LD", asteroid.missDistanceLunar))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(threatColor)

                    Text(String(format: "%.1f km/s", asteroid.relativeVelocity))
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Text(asteroid.threatLevel)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(threatColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(threatColor.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(10)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private var threatColor: Color {
        switch asteroid.threatLevel {
        case "CLOSE": return .red
        case "WATCH": return .orange
        default: return .green
        }
    }
}

// MARK: - Doomsday Clock

struct DoomsdayClockView: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "clock.fill")
                .font(.system(size: 28))
                .foregroundColor(.red)

            VStack(alignment: .leading, spacing: 4) {
                Text("89 SECONDS")
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .foregroundColor(.red)
                Text("TO MIDNIGHT")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.red.opacity(0.7))
                Text("Bulletin of the Atomic Scientists — 2025")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Aurora Oval View (polar projection of aurora probability)

struct AuroraOvalView: View {
    let data: [[Int]] // [lon, lat, probability]
    let kpIndex: Double

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            let radius = min(centerX, centerY) * 0.9

            // Draw polar grid
            for r in stride(from: 0.25, through: 1.0, by: 0.25) {
                let gridPath = Path(ellipseIn: CGRect(
                    x: centerX - radius * r,
                    y: centerY - radius * r,
                    width: radius * r * 2,
                    height: radius * r * 2
                ))
                context.stroke(gridPath, with: .color(.white.opacity(0.08)), lineWidth: 0.5)
            }

            // Plot aurora data points
            let intensityScale = max(0.5, min(2.0, kpIndex / 5.0))
            for point in data {
                let lon = Double(point[0])
                let lat = Double(point[1])
                let prob = Double(point[2])

                // Polar projection: latitude maps to radius (90° = center, 0° = edge)
                // Only show northern hemisphere (lat > 0)
                guard lat > 30 else { continue }
                let normalizedLat = (90.0 - lat) / 60.0 // 0 at pole, 1 at lat 30
                let r = normalizedLat * radius

                // Longitude maps to angle
                let angle = lon * .pi / 180.0 - .pi / 2 // Rotate so 0° is at top

                let x = centerX + r * cos(angle)
                let y = centerY + r * sin(angle)

                let dotSize = max(2, prob / 15.0 * intensityScale)
                let opacity = min(1.0, prob / 50.0 * intensityScale)

                // Aurora color: green for low, purple for high probability
                let color: Color = prob > 50 ? .purple : .green

                let dotRect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: dotRect), with: .color(color.opacity(opacity * 0.7)))

                // Glow effect
                let glowSize = dotSize * 2.5
                let glowRect = CGRect(x: x - glowSize / 2, y: y - glowSize / 2, width: glowSize, height: glowSize)
                context.fill(Path(ellipseIn: glowRect), with: .color(color.opacity(opacity * 0.15)))
            }

            // Label
            context.draw(
                Text("N")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray),
                at: CGPoint(x: centerX, y: centerY - radius - 8)
            )
        }
        .frame(height: 180)
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
    }
}
