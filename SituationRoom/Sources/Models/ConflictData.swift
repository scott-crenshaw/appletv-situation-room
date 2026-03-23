import Foundation

/// GDELT DOC API conflict article, keyword-geocoded to a Middle East location.
struct ConflictEvent: Identifiable {
    let id: String
    let title: String
    let source: String       // domain (e.g., "bbc.co.uk")
    let date: String         // seendate from GDELT
    let url: String?
    let latitude: Double?    // from keyword geocoding (nil = unlocated)
    let longitude: Double?
    let matchedLocation: String? // keyword that matched (e.g., "Iran")

    var intensity: String {
        // Articles about specific cities = higher specificity/intensity
        guard matchedLocation != nil else { return "LOW" }
        let title = self.title.lowercased()
        if title.contains("attack") || title.contains("strike") || title.contains("bomb") || title.contains("missile") || title.contains("kill") {
            return "CRITICAL"
        }
        if title.contains("military") || title.contains("troops") || title.contains("weapon") || title.contains("naval") {
            return "ELEVATED"
        }
        return "MODERATE"
    }

    var hasCoordinates: Bool { latitude != nil && longitude != nil }
}

/// Keyword-to-coordinate mapping for Middle East geocoding.
/// Maps place names found in article titles to approximate lat/lon.
let meLocationKeywords: [(keyword: String, lat: Double, lon: Double, name: String)] = [
    // Countries
    ("iran", 32.4, 53.7, "Iran"),
    ("iraq", 33.3, 44.4, "Iraq"),
    ("syria", 35.0, 38.5, "Syria"),
    ("yemen", 15.4, 44.2, "Yemen"),
    ("gaza", 31.5, 34.47, "Gaza"),
    ("lebanon", 33.9, 35.5, "Lebanon"),
    ("israel", 31.8, 35.2, "Israel"),
    ("saudi", 24.7, 46.7, "Saudi Arabia"),

    // Cities
    ("tehran", 35.7, 51.4, "Tehran"),
    ("baghdad", 33.3, 44.4, "Baghdad"),
    ("damascus", 33.5, 36.3, "Damascus"),
    ("aleppo", 36.2, 37.2, "Aleppo"),
    ("mosul", 36.3, 43.1, "Mosul"),
    ("basra", 30.5, 47.8, "Basra"),
    ("beirut", 33.9, 35.5, "Beirut"),
    ("sanaa", 15.4, 44.2, "Sanaa"),
    ("aden", 12.8, 45.0, "Aden"),
    ("riyadh", 24.7, 46.7, "Riyadh"),
    ("isfahan", 32.7, 51.7, "Isfahan"),
    ("kabul", 34.5, 69.2, "Kabul"),
    ("kirkuk", 35.5, 44.4, "Kirkuk"),
    ("idlib", 35.9, 36.6, "Idlib"),

    // Strategic locations
    ("hormuz", 26.5, 56.3, "Strait of Hormuz"),
    ("suez", 30.0, 32.6, "Suez Canal"),
    ("red sea", 20.0, 38.5, "Red Sea"),
    ("persian gulf", 26.5, 52.0, "Persian Gulf"),
    ("houthi", 15.4, 44.2, "Yemen (Houthi)"),
    ("hezbollah", 33.9, 35.5, "Lebanon (Hezbollah)"),
    ("natanz", 33.7, 51.7, "Natanz"),
    ("gulf of oman", 25.0, 58.0, "Gulf of Oman"),
]
