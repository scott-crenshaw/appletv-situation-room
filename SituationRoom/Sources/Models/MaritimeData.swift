import Foundation

/// AIS vessel position from Finnish Digitraffic
struct VesselPosition: Identifiable {
    let id: String          // MMSI
    let latitude: Double
    let longitude: Double
    let sog: Double         // Speed over ground (knots)
    let cog: Double         // Course over ground (degrees)
    let heading: Double     // True heading (degrees)
    let navStatus: Int      // 0=under way, 1=at anchor, 5=moored, etc.
    let timestamp: Date

    var isMoving: Bool { sog > 0.5 }

    var navStatusText: String {
        switch navStatus {
        case 0: return "UNDERWAY"
        case 1: return "ANCHORED"
        case 2: return "NOT CMD"
        case 3: return "RESTRICTED"
        case 5: return "MOORED"
        case 7: return "FISHING"
        case 8: return "SAILING"
        case 11: return "TOWING"
        case 14: return "AIS-SART"
        default: return "UNKNOWN"
        }
    }
}

/// AIS vessel metadata from Finnish Digitraffic
struct VesselInfo: Identifiable {
    let id: String          // MMSI
    let name: String
    let callSign: String
    let imo: Int
    let shipType: Int
    let destination: String

    var shipTypeText: String {
        switch shipType {
        case 30: return "FISHING"
        case 31...32: return "TOWING"
        case 33: return "DREDGER"
        case 34: return "DIVING"
        case 35: return "MILITARY"
        case 36: return "SAILING"
        case 37: return "PLEASURE"
        case 40...49: return "HSC"
        case 50: return "PILOT"
        case 51: return "SAR"
        case 52: return "TUG"
        case 53: return "PORT TEND"
        case 55: return "LAW ENFORC"
        case 60...69: return "PASSENGER"
        case 70...79: return "CARGO"
        case 80...89: return "TANKER"
        default: return "OTHER"
        }
    }

    var shipTypeColor: String {
        switch shipType {
        case 35: return "red"         // Military
        case 60...69: return "blue"   // Passenger
        case 70...79: return "green"  // Cargo
        case 80...89: return "orange" // Tanker
        case 30: return "cyan"        // Fishing
        case 51: return "yellow"      // SAR
        default: return "gray"
        }
    }
}
