import Foundation

struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let source: String
    let publishedAt: Date?
    let link: String?
    let category: NewsCategory

    enum NewsCategory: String, CaseIterable {
        case breaking = "BREAKING"
        case geopolitics = "GEOPOLITICS"
        case military = "MILITARY"
        case markets = "MARKETS"
        case tech = "TECH"
        case crisis = "CRISIS"
        case general = "NEWS"
    }

    var timeAgo: String {
        guard let date = publishedAt else { return "" }
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

/// Earthquake from USGS GeoJSON feed
struct Earthquake: Identifiable, Codable {
    let id: String
    let magnitude: Double
    let place: String
    let time: Date
    let latitude: Double
    let longitude: Double
    let depth: Double

    var formattedMagnitude: String {
        String(format: "M%.1f", magnitude)
    }

    var severityColor: String {
        switch magnitude {
        case ..<5.0: return "yellow"
        case ..<6.0: return "orange"
        case ..<7.0: return "red"
        default: return "red"
        }
    }
}

/// USGS GeoJSON response structure
struct USGSResponse: Codable {
    let features: [USGSFeature]

    struct USGSFeature: Codable {
        let id: String
        let properties: Properties
        let geometry: Geometry

        struct Properties: Codable {
            let mag: Double?
            let place: String?
            let time: Int64?
        }

        struct Geometry: Codable {
            let coordinates: [Double] // [lon, lat, depth]
        }
    }
}
