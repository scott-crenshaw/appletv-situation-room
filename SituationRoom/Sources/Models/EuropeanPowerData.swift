import Foundation
import CoreLocation

// MARK: - Country Definitions

struct PowerCountry: Identifiable {
    let id: String              // Country code (de, fr, etc.)
    let name: String            // Display name
    let biddingZone: String     // For price API (DE-LU, FR, etc.)
    let genCode: String         // For generation API (usually same as id)
    let coordinate: CLLocationCoordinate2D

    static let all: [PowerCountry] = [
        PowerCountry(id: "de", name: "GERMANY",     biddingZone: "DE-LU",    genCode: "de", coordinate: .init(latitude: 51.2, longitude: 10.4)),
        PowerCountry(id: "fr", name: "FRANCE",       biddingZone: "FR",       genCode: "fr", coordinate: .init(latitude: 46.6, longitude: 2.2)),
        PowerCountry(id: "es", name: "SPAIN",        biddingZone: "ES",       genCode: "es", coordinate: .init(latitude: 40.4, longitude: -3.7)),
        PowerCountry(id: "it", name: "ITALY",        biddingZone: "IT-North", genCode: "it", coordinate: .init(latitude: 42.5, longitude: 12.5)),
        PowerCountry(id: "pl", name: "POLAND",       biddingZone: "PL",       genCode: "pl", coordinate: .init(latitude: 52.0, longitude: 19.0)),
        PowerCountry(id: "nl", name: "NETHERLANDS",  biddingZone: "NL",       genCode: "nl", coordinate: .init(latitude: 52.4, longitude: 4.9)),
        PowerCountry(id: "be", name: "BELGIUM",      biddingZone: "BE",       genCode: "be", coordinate: .init(latitude: 50.8, longitude: 4.4)),
        PowerCountry(id: "at", name: "AUSTRIA",      biddingZone: "AT",       genCode: "at", coordinate: .init(latitude: 47.5, longitude: 14.5)),
        PowerCountry(id: "se", name: "SWEDEN",       biddingZone: "SE4",      genCode: "se", coordinate: .init(latitude: 62.0, longitude: 15.0)),
        PowerCountry(id: "no", name: "NORWAY",       biddingZone: "NO1",      genCode: "no", coordinate: .init(latitude: 64.0, longitude: 11.0)),
        PowerCountry(id: "dk", name: "DENMARK",      biddingZone: "DK1",      genCode: "dk", coordinate: .init(latitude: 56.0, longitude: 10.0)),
        PowerCountry(id: "fi", name: "FINLAND",      biddingZone: "FI",       genCode: "fi", coordinate: .init(latitude: 64.0, longitude: 26.0)),
        PowerCountry(id: "cz", name: "CZECH REP",    biddingZone: "CZ",       genCode: "cz", coordinate: .init(latitude: 49.8, longitude: 15.5)),
        PowerCountry(id: "gr", name: "GREECE",       biddingZone: "GR",       genCode: "gr", coordinate: .init(latitude: 39.0, longitude: 22.0)),
        PowerCountry(id: "pt", name: "PORTUGAL",     biddingZone: "PT",       genCode: "pt", coordinate: .init(latitude: 39.4, longitude: -8.2)),
    ]
}

// MARK: - Power Data

struct CountryPowerData: Identifiable {
    let id: String              // Country code
    let country: PowerCountry
    var price: Double?          // EUR/MWh (latest 15-min period)
    var generationMix: GenerationMix?

    /// Price stress level for color coding
    var stressLevel: PriceStress {
        guard let p = price else { return .unknown }
        if p < 0    { return .negative }
        if p < 30   { return .low }
        if p < 80   { return .normal }
        if p < 150  { return .high }
        return .critical
    }
}

enum PriceStress {
    case negative, low, normal, high, critical, unknown
}

struct GenerationMix {
    var nuclear: Double = 0
    var windOnshore: Double = 0
    var windOffshore: Double = 0
    var solar: Double = 0
    var gas: Double = 0
    var coalLignite: Double = 0
    var coalHard: Double = 0
    var hydro: Double = 0       // run-of-river + reservoir + pumped storage
    var biomass: Double = 0
    var other: Double = 0       // waste, geothermal, oil, coal-derived gas, others
    var load: Double = 0
    var renewableShare: Double = 0  // 0–100 percentage

    var totalWind: Double { windOnshore + windOffshore }
    var totalCoal: Double { coalLignite + coalHard }
    var totalGeneration: Double {
        nuclear + totalWind + solar + gas + totalCoal + hydro + biomass + other
    }

    /// Fuel fractions for stacked bar (ordered by visual priority)
    var fuelFractions: [(label: String, fraction: Double, color: String)] {
        let total = max(totalGeneration, 1)
        return [
            ("NUC",   nuclear / total,   "purple"),
            ("WIND",  totalWind / total, "cyan"),
            ("SOLAR", solar / total,     "yellow"),
            ("HYDRO", hydro / total,     "blue"),
            ("GAS",   gas / total,       "orange"),
            ("COAL",  totalCoal / total, "gray"),
            ("BIO",   biomass / total,   "green"),
            ("OTHER", other / total,     "white"),
        ].filter { $0.fraction > 0.005 }
    }
}
