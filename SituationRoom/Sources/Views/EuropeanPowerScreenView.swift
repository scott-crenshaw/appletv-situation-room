import SwiftUI
import MapKit

/// Screen 17: European Power Grid — electricity prices + generation mix across Europe.
/// Price-colored country annotations on dark map + sorted country table with fuel mix bars.
struct EuropeanPowerScreenView: View {
    @ObservedObject var state: DashboardState

    private var sortedData: [CountryPowerData] {
        state.europeanPowerData.sorted { ($0.price ?? -999) > ($1.price ?? -999) }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Left: Europe map with price annotations (2/3 width)
            VStack(spacing: 12) {
                sectionHeader(
                    "EUROPEAN POWER GRID",
                    subtitle: "\(state.europeanPowerData.count) MARKETS — ENERGY CHARTS"
                )
                PowerMapView(powerData: state.europeanPowerData)
                    .frame(maxHeight: .infinity)
                PowerSummaryBar(powerData: state.europeanPowerData)
            }
            .frame(maxWidth: .infinity)

            // Right: Country table
            VStack(spacing: 12) {
                sectionHeader("PRICE STRESS", subtitle: "EUR/MWh")
                PriceStressLegend()
                sectionHeader("MARKET STATUS", subtitle: nil)
                CountryPowerTable(powerData: sortedData)
                    .frame(maxHeight: .infinity)
                FuelTypeLegend()
            }
            .frame(width: 580)
        }
        .padding(24)
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

// MARK: - Power Map

struct PowerMapView: View {
    let powerData: [CountryPowerData]

    @State private var cameraPosition: MapCameraPosition = .camera(MapCamera(
        centerCoordinate: CLLocationCoordinate2D(latitude: 52, longitude: 15),
        distance: 6_000_000
    ))

    var body: some View {
        Map(position: $cameraPosition, interactionModes: []) {
            ForEach(powerData) { data in
                Annotation("", coordinate: data.country.coordinate, anchor: .center) {
                    PriceAnnotation(data: data)
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

// MARK: - Price Annotation (map dot)

struct PriceAnnotation: View {
    let data: CountryPowerData

    private var color: Color {
        switch data.stressLevel {
        case .negative: return .cyan
        case .low:      return .green
        case .normal:   return .yellow
        case .high:     return .orange
        case .critical: return .red
        case .unknown:  return .gray
        }
    }

    var body: some View {
        VStack(spacing: 1) {
            // Country code
            Text(data.id.uppercased())
                .font(.system(size: 9, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
            // Price badge
            if let price = data.price {
                Text(priceText(price))
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundColor(color)
            }
            // Renewable share
            if let mix = data.generationMix, mix.renewableShare > 0 {
                Text("\(Int(mix.renewableShare))%R")
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                    .foregroundColor(.green.opacity(0.7))
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Color.black.opacity(0.7))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }

    private func priceText(_ price: Double) -> String {
        if abs(price) >= 100 {
            return String(format: "%.0f", price)
        }
        return String(format: "%.1f", price)
    }
}

// MARK: - Country Power Table

struct CountryPowerTable: View {
    let powerData: [CountryPowerData]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 5) {
                ForEach(powerData) { data in
                    CountryPowerRow(data: data)
                }
            }
        }
    }
}

struct CountryPowerRow: View {
    let data: CountryPowerData

    private var priceColor: Color {
        switch data.stressLevel {
        case .negative: return .cyan
        case .low:      return .green
        case .normal:   return .yellow
        case .high:     return .orange
        case .critical: return .red
        case .unknown:  return .gray
        }
    }

    var body: some View {
        VStack(spacing: 3) {
            HStack(spacing: 8) {
                // Country name
                Text(data.country.name)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .frame(width: 120, alignment: .leading)

                // Price
                if let price = data.price {
                    Text(String(format: price >= 100 ? "%.0f" : "%.1f", price))
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(priceColor)
                        .frame(width: 60, alignment: .trailing)
                } else {
                    Text("--")
                        .font(.system(size: 14, weight: .heavy, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(width: 60, alignment: .trailing)
                }

                // Renewable share
                if let mix = data.generationMix, mix.renewableShare > 0 {
                    Text("\(Int(mix.renewableShare))%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.green.opacity(0.8))
                        .frame(width: 40, alignment: .trailing)
                } else {
                    Text("--")
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.gray)
                        .frame(width: 40, alignment: .trailing)
                }

                // Load
                if let mix = data.generationMix, mix.load > 0 {
                    Text(formatGW(mix.load))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 50, alignment: .trailing)
                } else {
                    Spacer().frame(width: 50)
                }

                // Generation mix bar
                if let mix = data.generationMix {
                    GenerationBar(mix: mix)
                        .frame(maxWidth: .infinity)
                        .frame(height: 8)
                } else {
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.02))
        .cornerRadius(4)
    }

    private func formatGW(_ mw: Double) -> String {
        if mw >= 1000 {
            return String(format: "%.0fGW", mw / 1000)
        }
        return String(format: "%.0fMW", mw)
    }
}

// MARK: - Generation Mix Bar

struct GenerationBar: View {
    let mix: GenerationMix

    private static let fuelColors: [String: Color] = [
        "purple": .purple,
        "cyan": .cyan,
        "yellow": .yellow,
        "blue": .blue,
        "orange": .orange,
        "gray": .gray,
        "green": .green,
        "white": .white.opacity(0.3),
    ]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(mix.fuelFractions, id: \.label) { item in
                    Rectangle()
                        .fill(Self.fuelColors[item.color] ?? .gray)
                        .frame(width: max(geo.size.width * item.fraction, 1))
                }
            }
            .cornerRadius(2)
        }
    }
}

// MARK: - Power Summary Bar

struct PowerSummaryBar: View {
    let powerData: [CountryPowerData]

    private var avgPrice: Double {
        let prices = powerData.compactMap { $0.price }
        guard !prices.isEmpty else { return 0 }
        return prices.reduce(0, +) / Double(prices.count)
    }

    private var maxPrice: (String, Double)? {
        guard let max = powerData.compactMap({ d in d.price.map { (d.country.name, $0) } }).max(by: { $0.1 < $1.1 }) else { return nil }
        return max
    }

    private var minPrice: (String, Double)? {
        guard let min = powerData.compactMap({ d in d.price.map { (d.country.name, $0) } }).min(by: { $0.1 < $1.1 }) else { return nil }
        return min
    }

    private var avgRenewable: Double {
        let shares = powerData.compactMap { $0.generationMix?.renewableShare }.filter { $0 > 0 }
        guard !shares.isEmpty else { return 0 }
        return shares.reduce(0, +) / Double(shares.count)
    }

    var body: some View {
        HStack(spacing: 20) {
            statItem("AVG PRICE", String(format: "%.1f", avgPrice), priceColor(avgPrice))
            if let (name, price) = maxPrice {
                statItem("HIGHEST", "\(String(name.prefix(3))) \(String(format: "%.0f", price))", .red)
            }
            if let (name, price) = minPrice {
                statItem("LOWEST", "\(String(name.prefix(3))) \(String(format: "%.0f", price))", price < 0 ? .cyan : .green)
            }
            statItem("RENEWABLE", String(format: "%.0f%%", avgRenewable), .green)
            statItem("MARKETS", "\(powerData.count)", .cyan)
            statItem("SOURCE", "ENERGY CHARTS", .gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }

    private func priceColor(_ price: Double) -> Color {
        if price < 0   { return .cyan }
        if price < 30  { return .green }
        if price < 80  { return .yellow }
        if price < 150 { return .orange }
        return .red
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

// MARK: - Price Stress Legend

struct PriceStressLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            legendItem("<0", .cyan, "SURPLUS")
            legendItem("<30", .green, "LOW")
            legendItem("<80", .yellow, "NORMAL")
            legendItem("<150", .orange, "HIGH")
            legendItem("150+", .red, "CRISIS")
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private func legendItem(_ threshold: String, _ color: Color, _ label: String) -> some View {
        VStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(threshold)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
    }
}

// MARK: - Fuel Type Legend

struct FuelTypeLegend: View {
    var body: some View {
        HStack(spacing: 10) {
            fuelItem("NUC", .purple)
            fuelItem("WIND", .cyan)
            fuelItem("SOLAR", .yellow)
            fuelItem("HYDRO", .blue)
            fuelItem("GAS", .orange)
            fuelItem("COAL", .gray)
            fuelItem("BIO", .green)
        }
        .padding(8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
    }

    private func fuelItem(_ label: String, _ color: Color) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: 10, height: 6)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
