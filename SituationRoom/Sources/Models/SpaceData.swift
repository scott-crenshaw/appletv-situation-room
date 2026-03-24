import Foundation

/// NOAA Space Weather Prediction Center data
struct SpaceWeather {
    let kpIndex: Double          // 0-9 scale
    let kpCategory: String       // "G0" through "G5"
    let solarWindSpeed: Double   // km/s
    let solarWindDensity: Double // protons/cm³
    let bzComponent: Double      // nT (negative = geoeffective)
    let lastUpdate: Date

    var stormLevel: String {
        switch kpIndex {
        case ..<4: return "QUIET"
        case ..<5: return "UNSETTLED"
        case ..<6: return "STORM G1"
        case ..<7: return "STORM G2"
        case ..<8: return "STORM G3"
        case ..<9: return "STORM G4"
        default:   return "STORM G5"
        }
    }

    var isStorming: Bool { kpIndex >= 5 }
}

/// ISS current position
struct ISSPosition {
    let latitude: Double
    let longitude: Double
    let timestamp: Date
}

/// NASA JPL asteroid close approach
struct AsteroidApproach: Identifiable {
    let id: String
    let name: String
    let closeApproachDate: String   // "YYYY-MMM-DD" format from JPL
    let missDistanceLunar: Double   // in lunar distances
    let missDistanceKm: Double
    let relativeVelocity: Double    // km/s
    let diameterMin: Double?        // meters (estimated)
    let diameterMax: Double?        // meters (estimated)
    let isPotentiallyHazardous: Bool

    var threatLevel: String {
        if missDistanceLunar < 1.0 { return "CLOSE" }
        if missDistanceLunar < 5.0 { return "WATCH" }
        return "NOMINAL"
    }
}

/// NASA DONKI solar flare event
struct SolarFlare: Identifiable {
    let id: String
    let classType: String      // "M1.3", "X2.1", "C5.0"
    let beginTime: Date
    let peakTime: Date?
    let sourceLocation: String // "S14E10"
    let activeRegionNum: Int?

    var classLetter: String { String(classType.prefix(1)) }

    var flareColor: String {
        switch classLetter {
        case "X": return "red"
        case "M": return "orange"
        case "C": return "yellow"
        default: return "green"
        }
    }
}

/// NASA DONKI coronal mass ejection
struct CMEEvent: Identifiable {
    let id: String
    let startTime: Date
    let sourceLocation: String?
    let speed: Double?          // km/s
    let halfAngle: Double?      // degrees
    let isEarthDirected: Bool
    let note: String
}

/// NOAA SWPC space weather scales (R/S/G) — current + 3-day forecast
struct SpaceWeatherScales {
    let timestamp: Date
    let current: ScaleSet       // Right now
    let today: ForecastSet      // Remaining today
    let tomorrow: ForecastSet   // Tomorrow
    let dayAfter: ForecastSet   // Day after tomorrow

    struct ScaleSet {
        let radio: Int          // R0-R5
        let solar: Int          // S0-S5
        let geomag: Int         // G0-G5
    }

    struct ForecastSet {
        let radioMinorProb: Int? // % chance of R1-R2
        let radioMajorProb: Int? // % chance of R3+
        let solarProb: Int?      // % chance of S1+
        let geomagScale: Int     // predicted G scale
    }
}

/// NASA EONET natural event
struct NaturalEvent: Identifiable {
    let id: String
    let title: String
    let category: String        // "Wildfires", "Volcanoes", "Severe Storms", etc.
    let date: Date?
    let latitude: Double?
    let longitude: Double?
    let sourceURL: String?

    var categoryIcon: String {
        switch category.lowercased() {
        case let c where c.contains("fire") || c.contains("wildfire"): return "flame.fill"
        case let c where c.contains("volcano"): return "mountain.2.fill"
        case let c where c.contains("storm") || c.contains("cyclone"): return "hurricane"
        case let c where c.contains("flood"): return "water.waves"
        case let c where c.contains("ice") || c.contains("snow"): return "snowflake"
        case let c where c.contains("drought"): return "sun.max.fill"
        case let c where c.contains("earthquake"): return "waveform.path.ecg"
        case let c where c.contains("landslide"): return "triangle.fill"
        default: return "exclamationmark.triangle.fill"
        }
    }
}
