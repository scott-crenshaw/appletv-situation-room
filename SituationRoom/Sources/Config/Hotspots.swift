import CoreLocation

/// Geopolitical hotspots from World Monitor's geo config.
/// Used as map annotations and for auto-pan regional presets.
struct Hotspot: Identifiable {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let category: HotspotCategory
    let threatLevel: ThreatLevel

    enum HotspotCategory: String, CaseIterable {
        case conflict = "Conflict"
        case militaryBase = "Base"
        case nuclearSite = "Nuclear"
        case hotspot = "Hotspot"
        case waterway = "Waterway"
    }

    enum ThreatLevel: String, CaseIterable {
        case critical = "Critical"
        case high = "High"
        case elevated = "Elevated"
        case monitoring = "Monitoring"
        case low = "Low"

        var color: String {
            switch self {
            case .critical: return "red"
            case .high: return "orange"
            case .elevated: return "yellow"
            case .monitoring: return "blue"
            case .low: return "green"
            }
        }
    }
}

/// Regional presets for auto-panning the map
struct MapRegion: Identifiable {
    let id: String
    let name: String
    let center: CLLocationCoordinate2D
    let spanLat: Double
    let spanLon: Double
}

let mapRegions: [MapRegion] = [
    MapRegion(id: "global", name: "Global", center: CLLocationCoordinate2D(latitude: 20, longitude: 0), spanLat: 120, spanLon: 180),
    MapRegion(id: "middleeast", name: "Middle East", center: CLLocationCoordinate2D(latitude: 30, longitude: 45), spanLat: 25, spanLon: 30),
    MapRegion(id: "europe", name: "Europe", center: CLLocationCoordinate2D(latitude: 50, longitude: 15), spanLat: 30, spanLon: 40),
    MapRegion(id: "asia", name: "Asia-Pacific", center: CLLocationCoordinate2D(latitude: 30, longitude: 115), spanLat: 40, spanLon: 60),
    MapRegion(id: "americas", name: "Americas", center: CLLocationCoordinate2D(latitude: 25, longitude: -90), spanLat: 60, spanLon: 60),
    MapRegion(id: "ukraine", name: "Ukraine", center: CLLocationCoordinate2D(latitude: 48.5, longitude: 35), spanLat: 10, spanLon: 15),
    MapRegion(id: "taiwan", name: "Taiwan Strait", center: CLLocationCoordinate2D(latitude: 24, longitude: 120), spanLat: 10, spanLon: 10),
    MapRegion(id: "iran", name: "Iran Theater", center: CLLocationCoordinate2D(latitude: 32, longitude: 53), spanLat: 15, spanLon: 20),
]

/// Curated global hotspots — conflicts, tension points, nuclear sites, bases, waterways
let sampleHotspots: [Hotspot] = [
    // Active conflicts
    Hotspot(id: "ukraine-front", name: "Ukraine Front", coordinate: CLLocationCoordinate2D(latitude: 48.0, longitude: 37.8), category: .conflict, threatLevel: .critical),
    Hotspot(id: "gaza", name: "Gaza", coordinate: CLLocationCoordinate2D(latitude: 31.5, longitude: 34.47), category: .conflict, threatLevel: .critical),
    Hotspot(id: "sudan", name: "Sudan", coordinate: CLLocationCoordinate2D(latitude: 15.5, longitude: 32.5), category: .conflict, threatLevel: .high),
    Hotspot(id: "myanmar", name: "Myanmar", coordinate: CLLocationCoordinate2D(latitude: 19.7, longitude: 96.2), category: .conflict, threatLevel: .high),
    Hotspot(id: "sahel", name: "Sahel Region", coordinate: CLLocationCoordinate2D(latitude: 15.0, longitude: 2.0), category: .conflict, threatLevel: .elevated),

    // Hotspots / tension points
    Hotspot(id: "taiwan-strait", name: "Taiwan Strait", coordinate: CLLocationCoordinate2D(latitude: 24.0, longitude: 119.5), category: .hotspot, threatLevel: .elevated),
    Hotspot(id: "south-china-sea", name: "South China Sea", coordinate: CLLocationCoordinate2D(latitude: 15.0, longitude: 115.0), category: .hotspot, threatLevel: .elevated),
    Hotspot(id: "korean-dmz", name: "Korean DMZ", coordinate: CLLocationCoordinate2D(latitude: 38.0, longitude: 127.0), category: .hotspot, threatLevel: .monitoring),
    Hotspot(id: "kaliningrad", name: "Kaliningrad", coordinate: CLLocationCoordinate2D(latitude: 54.7, longitude: 20.5), category: .hotspot, threatLevel: .monitoring),
    Hotspot(id: "hormuz", name: "Strait of Hormuz", coordinate: CLLocationCoordinate2D(latitude: 26.5, longitude: 56.3), category: .waterway, threatLevel: .elevated),

    // Nuclear sites
    Hotspot(id: "natanz", name: "Natanz (Iran)", coordinate: CLLocationCoordinate2D(latitude: 33.7, longitude: 51.7), category: .nuclearSite, threatLevel: .high),
    Hotspot(id: "yongbyon", name: "Yongbyon (DPRK)", coordinate: CLLocationCoordinate2D(latitude: 39.8, longitude: 125.8), category: .nuclearSite, threatLevel: .high),
    Hotspot(id: "zaporizhzhia", name: "Zaporizhzhia NPP", coordinate: CLLocationCoordinate2D(latitude: 47.5, longitude: 34.6), category: .nuclearSite, threatLevel: .critical),

    // Key military bases
    Hotspot(id: "ramstein", name: "Ramstein AFB", coordinate: CLLocationCoordinate2D(latitude: 49.44, longitude: 7.6), category: .militaryBase, threatLevel: .low),
    Hotspot(id: "diego-garcia", name: "Diego Garcia", coordinate: CLLocationCoordinate2D(latitude: -7.3, longitude: 72.4), category: .militaryBase, threatLevel: .monitoring),
    Hotspot(id: "al-udeid", name: "Al Udeid (Qatar)", coordinate: CLLocationCoordinate2D(latitude: 25.1, longitude: 51.3), category: .militaryBase, threatLevel: .monitoring),
    Hotspot(id: "yokosuka", name: "Yokosuka (Japan)", coordinate: CLLocationCoordinate2D(latitude: 35.3, longitude: 139.65), category: .militaryBase, threatLevel: .monitoring),
    Hotspot(id: "pearl-harbor", name: "Pearl Harbor", coordinate: CLLocationCoordinate2D(latitude: 21.35, longitude: -157.95), category: .militaryBase, threatLevel: .low),

    // Strategic waterways
    Hotspot(id: "malacca", name: "Strait of Malacca", coordinate: CLLocationCoordinate2D(latitude: 2.5, longitude: 101.5), category: .waterway, threatLevel: .monitoring),
    Hotspot(id: "suez", name: "Suez Canal", coordinate: CLLocationCoordinate2D(latitude: 30.5, longitude: 32.3), category: .waterway, threatLevel: .elevated),
    Hotspot(id: "bab-el-mandeb", name: "Bab el-Mandeb", coordinate: CLLocationCoordinate2D(latitude: 12.6, longitude: 43.3), category: .waterway, threatLevel: .high),
]
