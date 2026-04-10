import Foundation

/// Space launch data from Launch Library 2 (The Space Devs).
struct SpaceLaunch: Identifiable {
    let id: String
    let name: String              // "Rocket | Mission"
    let rocketName: String        // Just the rocket/vehicle
    let missionName: String       // Just the mission
    let net: Date                 // No Earlier Than
    let netPrecision: String      // "SEC", "MIN", "HOUR", "DAY", "MONTH"
    let status: LaunchStatus
    let probability: Int?         // 0-100 percent, can be nil
    let weatherConcerns: String?
    let providerName: String
    let providerType: String      // "Government", "Commercial"
    let missionDescription: String?
    let missionType: String?      // "Communications", "Earth Science", etc.
    let orbitName: String?        // "LEO", "GTO", "Lunar flyby", etc.
    let padName: String
    let locationName: String      // "Kennedy Space Center, FL, USA"
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let imageURL: String?
    let webcastLive: Bool

    /// Countdown string relative to now: "T-02:14:33" or "T+00:05:12"
    var countdownString: String {
        let interval = net.timeIntervalSinceNow
        let prefix = interval > 0 ? "T-" : "T+"
        let abs = Int(abs(interval))
        let days = abs / 86400
        let hours = (abs % 86400) / 3600
        let minutes = (abs % 3600) / 60
        let seconds = abs % 60
        if days > 0 {
            return "\(prefix)\(days)d \(String(format: "%02d:%02d:%02d", hours, minutes, seconds))"
        }
        return "\(prefix)\(String(format: "%02d:%02d:%02d", hours, minutes, seconds))"
    }

    /// Human-readable date for launches far in the future
    var dateString: String {
        let formatter = DateFormatter()
        switch netPrecision {
        case "SEC", "MIN":
            formatter.dateFormat = "MMM dd HH:mm"
        case "HOUR":
            formatter.dateFormat = "MMM dd HH:mm"
        case "DAY":
            formatter.dateFormat = "MMM dd"
        default:
            formatter.dateFormat = "MMM yyyy"
        }
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: net) + " UTC"
    }

    /// Is this launch happening within the next 24 hours?
    var isImminent: Bool {
        net.timeIntervalSinceNow > 0 && net.timeIntervalSinceNow < 86400
    }

    /// Is this launch happening within the next hour?
    var isVeryImminent: Bool {
        net.timeIntervalSinceNow > 0 && net.timeIntervalSinceNow < 3600
    }

    /// Short provider abbreviation
    var providerAbbrev: String {
        let abbrevs: [String: String] = [
            "National Aeronautics and Space Administration": "NASA",
            "Space Exploration Technologies Corp.": "SPACEX",
            "SpaceX": "SPACEX",
            "China Aerospace Science and Technology Corporation": "CASC",
            "Russian Federal Space Agency (ROSCOSMOS)": "ROSCOSMOS",
            "Indian Space Research Organization": "ISRO",
            "Japan Aerospace Exploration Agency": "JAXA",
            "Rocket Lab Ltd": "ROCKET LAB",
            "Rocket Lab": "ROCKET LAB",
            "United Launch Alliance": "ULA",
            "Arianespace": "ARIANESPACE",
            "Blue Origin": "BLUE ORIGIN",
            "Northrop Grumman Innovation Systems": "NORTHROP",
            "Korea Aerospace Research Institute": "KARI",
            "European Space Agency": "ESA",
            "Firefly Aerospace": "FIREFLY",
            "Relativity Space": "RELATIVITY",
        ]
        return abbrevs[providerName] ?? providerName.uppercased().prefix(12).description
    }
}

enum LaunchStatus: String {
    case go = "Go for Launch"
    case tbd = "To Be Determined"
    case tbc = "To Be Confirmed"
    case success = "Launch Successful"
    case failure = "Launch Failure"
    case partialFailure = "Partial Failure"
    case inFlight = "In Flight"
    case hold = "On Hold"
    case unknown = "Unknown"

    var abbrev: String {
        switch self {
        case .go: return "GO"
        case .tbd: return "TBD"
        case .tbc: return "TBC"
        case .success: return "SUCCESS"
        case .failure: return "FAILURE"
        case .partialFailure: return "PARTIAL"
        case .inFlight: return "IN FLIGHT"
        case .hold: return "HOLD"
        case .unknown: return "UNK"
        }
    }

    var isSuccessful: Bool { self == .success }
    var isFailed: Bool { self == .failure || self == .partialFailure }

    init(from statusName: String) {
        let lower = statusName.lowercased()
        if lower.contains("go for launch") { self = .go }
        else if lower.contains("to be determined") { self = .tbd }
        else if lower.contains("to be confirmed") { self = .tbc }
        else if lower.contains("success") { self = .success }
        else if lower.contains("partial") { self = .partialFailure }
        else if lower.contains("failure") { self = .failure }
        else if lower.contains("in flight") { self = .inFlight }
        else if lower.contains("hold") { self = .hold }
        else { self = .unknown }
    }
}
