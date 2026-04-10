import Foundation

/// WHO Disease Outbreak News alert, geocoded to country centroid.
struct OutbreakAlert: Identifiable {
    let id: String           // DON ID (e.g. "2026-DON596")
    let title: String        // Full WHO title
    let disease: String      // Extracted pathogen name
    let country: String      // Extracted country
    let date: Date
    let summary: String      // Overview text (truncated)
    let severity: BiosecurityLevel
    let latitude: Double
    let longitude: Double
    let bslLevel: Int        // BSL classification (2-4)

    var ageDescription: String {
        let days = Int(-date.timeIntervalSinceNow / 86400)
        if days == 0 { return "TODAY" }
        if days == 1 { return "1 DAY AGO" }
        return "\(days) DAYS AGO"
    }
}

enum BiosecurityLevel: String, CaseIterable {
    case critical = "CRITICAL"
    case high = "HIGH"
    case elevated = "ELEVATED"
    case low = "LOW"

    var color: String {
        switch self {
        case .critical: return "red"
        case .high: return "orange"
        case .elevated: return "yellow"
        case .low: return "green"
        }
    }
}

/// Global health baseline from disease.sh per-country data.
struct CountryHealthData: Identifiable {
    let id: String           // ISO country code
    let country: String
    let activeCases: Int
    let activePerMillion: Double
    let latitude: Double
    let longitude: Double
}

// MARK: - Pathogen Classification

/// Maps known pathogens to BSL level and severity.
let pathogenClassification: [(pattern: String, disease: String, bsl: Int, severity: BiosecurityLevel)] = [
    // BSL-4 — maximum containment
    ("marburg", "Marburg Virus", 4, .critical),
    ("ebola", "Ebola Virus", 4, .critical),
    ("nipah", "Nipah Virus", 4, .critical),
    ("hendra", "Hendra Virus", 4, .critical),
    ("crimean-congo", "CCHF Virus", 4, .critical),
    ("lassa", "Lassa Fever", 4, .critical),

    // BSL-3 — serious/lethal
    ("mers", "MERS-CoV", 3, .high),
    ("sars", "SARS-CoV", 3, .high),
    ("mpox", "Mpox Virus", 3, .high),
    ("monkeypox", "Mpox Virus", 3, .high),
    ("avian influenza", "Avian Influenza", 3, .high),
    ("h5n1", "Avian Influenza H5N1", 3, .high),
    ("h7n9", "Influenza A(H7N9)", 3, .high),
    ("plague", "Plague", 3, .high),
    ("rift valley", "Rift Valley Fever", 3, .high),
    ("yellow fever", "Yellow Fever", 3, .high),
    ("tuberculosis", "Tuberculosis", 3, .high),

    // BSL-2 — moderate
    ("cholera", "Cholera", 2, .elevated),
    ("dengue", "Dengue", 2, .elevated),
    ("zika", "Zika Virus", 2, .elevated),
    ("measles", "Measles", 2, .elevated),
    ("malaria", "Malaria", 2, .elevated),
    ("hiv", "HIV", 2, .elevated),
    ("influenza", "Influenza", 2, .elevated),
    ("west nile", "West Nile Virus", 2, .elevated),
    ("meningitis", "Meningitis", 2, .elevated),
    ("hepatitis", "Hepatitis", 2, .elevated),
    ("diphtheria", "Diphtheria", 2, .elevated),
    ("polio", "Poliomyelitis", 2, .elevated),
]

// MARK: - Country Geocoding

/// Maps country names from WHO DON titles to approximate centroids.
let countryGeocodeLookup: [(pattern: String, name: String, lat: Double, lon: Double)] = [
    // Africa
    ("ethiopia", "Ethiopia", 9.1, 40.5),
    ("democratic republic of the congo", "DRC", -4.0, 21.8),
    ("drc", "DRC", -4.0, 21.8),
    ("congo", "Congo", -4.3, 15.3),
    ("nigeria", "Nigeria", 9.1, 8.7),
    ("south africa", "South Africa", -30.6, 22.9),
    ("ghana", "Ghana", 7.9, -1.0),
    ("sierra leone", "Sierra Leone", 8.5, -11.8),
    ("liberia", "Liberia", 6.4, -9.4),
    ("mali", "Mali", 17.6, -4.0),
    ("sudan", "Sudan", 12.9, 30.2),
    ("south sudan", "South Sudan", 6.9, 31.3),
    ("zambia", "Zambia", -13.1, 27.8),
    ("zimbabwe", "Zimbabwe", -19.0, 29.2),
    ("togo", "Togo", 8.6, 1.2),
    ("gabon", "Gabon", -0.8, 11.6),
    ("uganda", "Uganda", 1.4, 32.3),
    ("kenya", "Kenya", -0.0, 37.9),
    ("tanzania", "Tanzania", -6.4, 34.9),
    ("mozambique", "Mozambique", -18.7, 35.5),
    ("cameroon", "Cameroon", 7.4, 12.4),
    ("guinea", "Guinea", 9.9, -9.7),
    ("senegal", "Senegal", 14.5, -14.5),
    ("angola", "Angola", -11.2, 17.9),
    ("madagascar", "Madagascar", -18.8, 46.9),

    // Asia
    ("india", "India", 20.6, 79.0),
    ("bangladesh", "Bangladesh", 23.7, 90.4),
    ("china", "China", 35.9, 104.2),
    ("indonesia", "Indonesia", -0.8, 113.9),
    ("vietnam", "Vietnam", 14.1, 108.3),
    ("pakistan", "Pakistan", 30.4, 69.3),
    ("philippines", "Philippines", 12.9, 121.8),
    ("japan", "Japan", 36.2, 138.3),
    ("south korea", "South Korea", 35.9, 127.8),
    ("korea", "Korea", 35.9, 127.8),
    ("thailand", "Thailand", 15.9, 100.9),
    ("myanmar", "Myanmar", 21.9, 95.9),
    ("cambodia", "Cambodia", 12.6, 105.0),
    ("hong kong", "Hong Kong", 22.4, 114.1),
    ("taiwan", "Taiwan", 23.7, 121.0),
    ("afghanistan", "Afghanistan", 33.9, 67.7),

    // Middle East
    ("saudi arabia", "Saudi Arabia", 23.9, 45.1),
    ("saudi", "Saudi Arabia", 23.9, 45.1),
    ("iran", "Iran", 32.4, 53.7),
    ("iraq", "Iraq", 33.2, 43.7),
    ("egypt", "Egypt", 26.8, 30.8),
    ("jordan", "Jordan", 30.6, 36.2),
    ("israel", "Israel", 31.0, 34.9),
    ("palestine", "Palestine", 31.9, 35.2),
    ("yemen", "Yemen", 15.6, 48.5),
    ("syria", "Syria", 34.8, 38.9),
    ("lebanon", "Lebanon", 33.9, 35.9),

    // Europe
    ("united kingdom", "United Kingdom", 55.4, -3.4),
    ("france", "France", 46.2, 2.2),
    ("germany", "Germany", 51.2, 10.4),
    ("italy", "Italy", 41.9, 12.6),
    ("spain", "Spain", 40.5, -3.7),
    ("russia", "Russia", 61.5, 105.3),
    ("turkey", "Turkey", 39.0, 35.2),
    ("ukraine", "Ukraine", 48.4, 31.2),

    // Americas
    ("united states", "United States", 37.1, -95.7),
    ("brazil", "Brazil", -14.2, -51.9),
    ("mexico", "Mexico", 23.6, -102.6),
    ("canada", "Canada", 56.1, -106.3),
    ("chile", "Chile", -35.7, -71.5),
    ("colombia", "Colombia", 4.6, -74.3),
    ("argentina", "Argentina", -38.4, -63.6),
    ("peru", "Peru", -9.2, -75.0),

    // Oceania
    ("australia", "Australia", -25.3, 133.8),
    ("new zealand", "New Zealand", -40.9, 174.9),

    // Multi-country / fallback
    ("global", "Global", 20.0, 0.0),
    ("multi-country", "Multi-country", 20.0, 0.0),
]

// MARK: - WHO Region Mapping

enum WHORegion: String, CaseIterable {
    case afro = "AFRO"    // Africa
    case emro = "EMRO"    // Eastern Mediterranean
    case searo = "SEARO"  // South-East Asia
    case wpro = "WPRO"    // Western Pacific
    case euro = "EURO"    // Europe
    case amro = "AMRO"    // Americas

    var displayName: String {
        switch self {
        case .afro: return "AFRICA"
        case .emro: return "E. MEDITERRANEAN"
        case .searo: return "SE ASIA"
        case .wpro: return "W. PACIFIC"
        case .euro: return "EUROPE"
        case .amro: return "AMERICAS"
        }
    }

    static func fromCountry(_ country: String) -> WHORegion {
        let c = country.lowercased()
        let africa = ["ethiopia", "drc", "congo", "nigeria", "south africa", "ghana", "sierra leone",
                       "liberia", "mali", "sudan", "south sudan", "zambia", "zimbabwe", "togo",
                       "gabon", "uganda", "kenya", "tanzania", "mozambique", "cameroon", "guinea",
                       "senegal", "angola", "madagascar"]
        let emro = ["saudi", "iran", "iraq", "egypt", "jordan", "israel", "palestine", "yemen",
                     "syria", "lebanon", "pakistan", "afghanistan"]
        let searo = ["india", "bangladesh", "indonesia", "thailand", "myanmar", "nepal", "sri lanka"]
        let wpro = ["china", "japan", "korea", "vietnam", "philippines", "cambodia", "hong kong",
                     "taiwan", "australia", "new zealand"]
        let amro = ["united states", "brazil", "mexico", "canada", "chile", "colombia", "argentina", "peru"]

        if africa.contains(where: { c.contains($0) }) { return .afro }
        if emro.contains(where: { c.contains($0) }) { return .emro }
        if searo.contains(where: { c.contains($0) }) { return .searo }
        if wpro.contains(where: { c.contains($0) }) { return .wpro }
        if amro.contains(where: { c.contains($0) }) { return .amro }
        return .euro // Default fallback
    }
}
