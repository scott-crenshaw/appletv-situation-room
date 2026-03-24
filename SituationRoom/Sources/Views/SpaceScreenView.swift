import SwiftUI

/// Space & Geophysical Intelligence screen.
/// Shows solar weather, ISS position, asteroid approaches, and natural events.
struct SpaceScreenView: View {
    @ObservedObject var state: DashboardState

    var body: some View {
        HStack(spacing: 16) {
            // Left column: Space Weather + Solar Image + ISS
            VStack(spacing: 12) {
                sectionHeader("SOLAR WEATHER")

                if let sw = state.spaceWeather {
                    SpaceWeatherPanel(weather: sw)
                } else {
                    loadingPlaceholder("Connecting to NOAA SWPC...")
                }

                // Live solar image (SUVI 195Å EUV)
                if let imgData = state.solarImageData, let uiImage = UIImage(data: imgData) {
                    sectionHeader("SOLAR IMAGERY — SUVI 195Å")
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 220)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                        )
                }

                sectionHeader("ISS TRACKER")
                if let iss = state.issPosition {
                    ISSPanel(position: iss)
                } else {
                    loadingPlaceholder("Locating ISS...")
                }

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Center column: Solar Events + Near-Earth Objects
            VStack(spacing: 12) {
                // Solar X-ray flux chart
                if !state.solarXrayFlux.isEmpty {
                    sectionHeader("GOES X-RAY FLUX (24H)")
                    SolarFlareChartView(data: state.solarXrayFlux)
                }

                // DONKI Solar Flares + CMEs
                if !state.solarFlares.isEmpty || !state.cmeEvents.isEmpty {
                    sectionHeader("SOLAR ACTIVITY — 7 DAY")
                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(state.solarFlares.prefix(6)) { flare in
                                SolarFlareRow(flare: flare)
                            }
                            ForEach(state.cmeEvents.prefix(4)) { cme in
                                CMERow(cme: cme)
                            }
                        }
                    }
                }

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

                Spacer()
            }
            .frame(maxWidth: .infinity)

            // Right column: 3-Day Forecast + Aurora + Starlink + Doomsday
            VStack(spacing: 12) {
                // Space Weather Scales (3-day forecast)
                if let scales = state.spaceWeatherScales {
                    sectionHeader("SPACE WEATHER OUTLOOK")
                    SpaceWeatherForecastPanel(scales: scales)
                }

                // Aurora oval
                if !state.auroraData.isEmpty {
                    sectionHeader("AURORA PROBABILITY")
                    AuroraOvalView(data: state.auroraData, kpIndex: state.spaceWeather?.kpIndex ?? 0)
                }

                // Satellite constellation
                if !state.satellitePositions.isEmpty {
                    sectionHeader("STARLINK CONSTELLATION")
                    SatelliteConstellationView(satellites: state.satellitePositions)
                }

                sectionHeader("DOOMSDAY CLOCK")
                DoomsdayClockView()

                Spacer()
            }
            .frame(width: 400)
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

// MARK: - Solar Flare X-ray Flux Chart

struct SolarFlareChartView: View {
    let data: [(Date, Double)]

    var body: some View {
        Canvas { context, size in
            guard data.count >= 2 else { return }

            let fluxValues = data.map { $0.1 }
            let logValues = fluxValues.map { log10(max($0, 1e-9)) }
            let minLog = logValues.min() ?? -9
            let maxLog = max(logValues.max() ?? -4, minLog + 1)
            let range = maxLog - minLog

            // Draw flux classification thresholds
            let thresholds: [(label: String, value: Double, color: Color)] = [
                ("X", -4, .red),
                ("M", -5, .orange),
                ("C", -6, .yellow),
                ("B", -7, .green),
            ]

            for threshold in thresholds {
                let y = size.height * (1 - CGFloat((threshold.value - minLog) / range))
                if y > 0 && y < size.height {
                    // Threshold line
                    var linePath = Path()
                    linePath.move(to: CGPoint(x: 0, y: y))
                    linePath.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(linePath, with: .color(threshold.color.opacity(0.2)), lineWidth: 0.5)

                    // Label
                    context.draw(
                        Text(threshold.label)
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(threshold.color.opacity(0.5)),
                        at: CGPoint(x: 10, y: y - 6)
                    )
                }
            }

            // Draw flux line
            var path = Path()
            for (i, entry) in data.enumerated() {
                let x = size.width * CGFloat(i) / CGFloat(data.count - 1)
                let logVal = log10(max(entry.1, 1e-9))
                let y = size.height * (1 - CGFloat((logVal - minLog) / range))

                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            // Glow effect
            context.stroke(path, with: .color(.cyan.opacity(0.15)), lineWidth: 6)
            context.stroke(path, with: .color(.cyan.opacity(0.4)), lineWidth: 2)
            context.stroke(path, with: .color(.cyan), lineWidth: 1)

            // Current flux level label
            if let lastFlux = fluxValues.last {
                let flareClass: String
                let classColor: Color
                switch log10(lastFlux) {
                case (-4)...: flareClass = "X-CLASS"; classColor = .red
                case (-5)..<(-4): flareClass = "M-CLASS"; classColor = .orange
                case (-6)..<(-5): flareClass = "C-CLASS"; classColor = .yellow
                default: flareClass = "B-CLASS"; classColor = .green
                }

                context.draw(
                    Text(flareClass)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(classColor),
                    at: CGPoint(x: size.width - 35, y: 10)
                )
            }
        }
        .frame(height: 120)
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(8)
    }
}

// MARK: - Satellite Constellation View

struct SatelliteConstellationView: View {
    let satellites: [APIService.SatellitePosition]

    var body: some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let centerY = size.height / 2
            let radius = min(centerX, centerY) - 4

            // Draw Earth circle
            let earthRect = CGRect(x: centerX - radius * 0.3, y: centerY - radius * 0.3,
                                   width: radius * 0.6, height: radius * 0.6)
            context.fill(Path(ellipseIn: earthRect), with: .color(Color(red: 0, green: 0.1, blue: 0.15)))
            context.stroke(Path(ellipseIn: earthRect), with: .color(.cyan.opacity(0.3)), lineWidth: 0.5)

            // Orbital ring
            let orbitRect = CGRect(x: centerX - radius, y: centerY - radius,
                                   width: radius * 2, height: radius * 2)
            context.stroke(Path(ellipseIn: orbitRect), with: .color(.cyan.opacity(0.08)), lineWidth: 0.5)

            // Plot satellite positions
            for sat in satellites {
                // Map lat/lon to 2D projection
                let lonRad = sat.longitude * .pi / 180
                let latRad = sat.latitude * .pi / 180

                let x = centerX + radius * 0.85 * cos(latRad) * sin(lonRad)
                let y = centerY - radius * 0.85 * sin(latRad)

                // Tiny glowing dot
                let dotSize: CGFloat = 2
                let dotRect = CGRect(x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize, height: dotSize)
                context.fill(Path(ellipseIn: dotRect), with: .color(.cyan.opacity(0.7)))

                // Glow
                let glowSize: CGFloat = 5
                let glowRect = CGRect(x: x - glowSize / 2, y: y - glowSize / 2, width: glowSize, height: glowSize)
                context.fill(Path(ellipseIn: glowRect), with: .color(.cyan.opacity(0.15)))
            }

            // Label
            context.draw(
                Text("\(satellites.count) ACTIVE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.6)),
                at: CGPoint(x: centerX, y: size.height - 6)
            )
        }
        .frame(height: 160)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyan.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - Solar Flare Row (DONKI)

struct SolarFlareRow: View {
    let flare: SolarFlare

    private var flareColor: Color {
        switch flare.classLetter {
        case "X": return .red
        case "M": return .orange
        case "C": return .yellow
        default: return .green
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(flare.classType)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(flareColor)
                .frame(width: 55, alignment: .leading)

            Image(systemName: "sun.max.fill")
                .font(.system(size: 12))
                .foregroundColor(flareColor)

            VStack(alignment: .leading, spacing: 1) {
                Text("FLARE \(flare.sourceLocation)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(timeAgo(flare.beginTime))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()

            if let region = flare.activeRegionNum {
                Text("AR\(region)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.7))
            }
        }
        .padding(8)
        .background(flareColor.opacity(0.06))
        .cornerRadius(6)
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - CME Row (DONKI)

struct CMERow: View {
    let cme: CMEEvent

    var body: some View {
        HStack(spacing: 10) {
            Text("CME")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.purple)
                .frame(width: 55, alignment: .leading)

            Image(systemName: "burst.fill")
                .font(.system(size: 12))
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 8) {
                    if let speed = cme.speed {
                        Text("\(Int(speed)) km/s")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                    if cme.isEarthDirected {
                        Text("EARTH-DIRECTED")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(3)
                    }
                }
                Text(timeAgo(cme.startTime))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(8)
        .background(Color.purple.opacity(0.06))
        .cornerRadius(6)
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Space Weather Forecast Panel (NOAA Scales 3-day)

struct SpaceWeatherForecastPanel: View {
    let scales: SpaceWeatherScales

    var body: some View {
        VStack(spacing: 10) {
            // Current conditions
            HStack(spacing: 16) {
                scaleIndicator("RADIO", scale: scales.current.radio, prefix: "R")
                scaleIndicator("SOLAR", scale: scales.current.solar, prefix: "S")
                scaleIndicator("GEOMAG", scale: scales.current.geomag, prefix: "G")
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            // 3-day forecast
            HStack(spacing: 0) {
                Text("3-DAY:")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.gray)
                    .frame(width: 60, alignment: .leading)

                forecastDay("TODAY", forecast: scales.today)
                forecastDay("TMW", forecast: scales.tomorrow)
                forecastDay("+2D", forecast: scales.dayAfter)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private func scaleIndicator(_ label: String, scale: Int, prefix: String) -> some View {
        VStack(spacing: 2) {
            Text("\(prefix)\(scale)")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(scaleColor(scale))
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }

    private func forecastDay(_ label: String, forecast: SpaceWeatherScales.ForecastSet) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            Text("G\(forecast.geomagScale)")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(scaleColor(forecast.geomagScale))
        }
        .frame(maxWidth: .infinity)
    }

    private func scaleColor(_ scale: Int) -> Color {
        switch scale {
        case 0: return .green
        case 1: return .yellow
        case 2: return .orange
        case 3...4: return .red
        default: return .red
        }
    }
}
