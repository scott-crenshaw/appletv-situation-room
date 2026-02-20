import Foundation

/// NWS severe weather alert
struct WeatherAlert: Identifiable {
    let id: String
    let event: String           // "Tornado Warning", "Severe Thunderstorm Watch", etc.
    let headline: String
    let severity: String        // "Extreme", "Severe", "Moderate", "Minor"
    let urgency: String         // "Immediate", "Expected", "Future"
    let areaDesc: String        // Affected areas
    let onset: Date?
    let expires: Date?

    var severityColor: String {
        switch severity.lowercased() {
        case "extreme": return "red"
        case "severe": return "orange"
        case "moderate": return "yellow"
        default: return "green"
        }
    }

    var eventIcon: String {
        let e = event.lowercased()
        if e.contains("tornado") { return "tornado" }
        if e.contains("hurricane") || e.contains("tropical") { return "hurricane" }
        if e.contains("thunder") || e.contains("lightning") { return "cloud.bolt.fill" }
        if e.contains("flood") { return "water.waves" }
        if e.contains("winter") || e.contains("blizzard") || e.contains("ice") || e.contains("snow") { return "snowflake" }
        if e.contains("heat") { return "sun.max.fill" }
        if e.contains("wind") { return "wind" }
        if e.contains("fire") { return "flame.fill" }
        if e.contains("fog") { return "cloud.fog.fill" }
        return "exclamationmark.triangle.fill"
    }
}

/// Recent CVE entry
struct CVEEntry: Identifiable {
    let id: String              // "CVE-2025-XXXXX"
    let summary: String
    let severity: String        // "CRITICAL", "HIGH", "MEDIUM", "LOW"
    let publishedDate: Date?
    let cvssScore: Double?

    var severityColor: String {
        switch severity.uppercased() {
        case "CRITICAL": return "red"
        case "HIGH": return "orange"
        case "MEDIUM": return "yellow"
        default: return "green"
        }
    }
}

/// Internet health / infrastructure status indicator
struct InfraStatus: Identifiable {
    let id: String
    let name: String            // "DNS Root", "Global BGP", "CDN", etc.
    let status: Status
    let detail: String

    enum Status: String {
        case operational = "OPERATIONAL"
        case degraded = "DEGRADED"
        case outage = "OUTAGE"
        case unknown = "UNKNOWN"
    }

    var statusColor: String {
        switch status {
        case .operational: return "green"
        case .degraded: return "yellow"
        case .outage: return "red"
        case .unknown: return "gray"
        }
    }
}
