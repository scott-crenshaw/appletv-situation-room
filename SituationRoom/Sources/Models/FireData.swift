import Foundation

/// NASA FIRMS VIIRS fire/thermal hotspot detection
struct FireHotspot: Identifiable {
    let id: String
    let latitude: Double
    let longitude: Double
    let brightness: Double      // bright_ti4 in Kelvin
    let frp: Double             // fire radiative power in MW
    let confidence: FireConfidence
    let acqDate: String         // yyyy-MM-dd
    let acqTime: String         // HHmm UTC
    let isDaytime: Bool
    let satellite: String       // "N" = Suomi NPP, "1" = NOAA-20

    enum FireConfidence: String {
        case low = "low"
        case nominal = "nominal"
        case high = "high"

        var color: String {
            switch self {
            case .low: return "yellow"
            case .nominal: return "orange"
            case .high: return "red"
            }
        }

        var opacity: Double {
            switch self {
            case .low: return 0.4
            case .nominal: return 0.7
            case .high: return 1.0
            }
        }
    }

    /// Relative size for map dot (based on FRP)
    var dotSize: Double {
        switch frp {
        case ..<5: return 4
        case ..<20: return 6
        case ..<50: return 8
        case ..<100: return 10
        default: return 14
        }
    }

    var formattedFRP: String {
        String(format: "%.1f MW", frp)
    }

    var formattedTime: String {
        guard acqTime.count == 4 else { return acqTime }
        let h = acqTime.prefix(2)
        let m = acqTime.suffix(2)
        return "\(h):\(m) UTC"
    }

    /// Region name derived from coordinates (rough)
    var region: String {
        switch (latitude, longitude) {
        case (let lat, let lon) where lat > 24 && lat < 50 && lon > -125 && lon < -66:
            return "North America"
        case (let lat, let lon) where lat > -35 && lat < 12 && lon > -82 && lon < -34:
            return "South America"
        case (let lat, let lon) where lat > 35 && lat < 72 && lon > -11 && lon < 40:
            return "Europe"
        case (let lat, let lon) where lat > -35 && lat < 37 && lon > -18 && lon < 52:
            return "Africa"
        case (let lat, let lon) where lat > 5 && lat < 55 && lon > 60 && lon < 150:
            return "Asia"
        case (let lat, let lon) where lat > -50 && lat < 0 && lon > 110 && lon < 180:
            return "Oceania"
        default:
            return "Other"
        }
    }
}
