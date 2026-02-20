import Foundation

/// Central API service for fetching data from public APIs.
/// All World Monitor data sources that don't require API keys are accessed directly.
/// Sources requiring keys go through a backend proxy (future enhancement).
actor APIService {
    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    // MARK: - Earthquakes (USGS — no auth required)

    func fetchEarthquakes() async throws -> [Earthquake] {
        let url = URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_day.geojson")!
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(USGSResponse.self, from: data)

        return response.features.compactMap { feature in
            guard let mag = feature.properties.mag,
                  let place = feature.properties.place,
                  let time = feature.properties.time,
                  feature.geometry.coordinates.count >= 3 else { return nil }

            return Earthquake(
                id: feature.id,
                magnitude: mag,
                place: place,
                time: Date(timeIntervalSince1970: Double(time) / 1000.0),
                latitude: feature.geometry.coordinates[1],
                longitude: feature.geometry.coordinates[0],
                depth: feature.geometry.coordinates[2]
            )
        }
        .sorted { $0.magnitude > $1.magnitude }
    }

    // MARK: - Market Data (Yahoo Finance v8 chart endpoint)

    func fetchMarketQuotes(symbols: [String]) async throws -> [MarketQuote] {
        // Yahoo v7 quote API requires auth now. Use v8 chart endpoint per-symbol.
        var quotes: [MarketQuote] = []

        // Fetch in parallel
        try await withThrowingTaskGroup(of: MarketQuote?.self) { group in
            for symbol in symbols {
                group.addTask {
                    try await self.fetchSingleQuote(symbol: symbol)
                }
            }
            for try await quote in group {
                if let quote { quotes.append(quote) }
            }
        }

        // Return in the same order as requested
        let symbolOrder = Dictionary(uniqueKeysWithValues: symbols.enumerated().map { ($1, $0) })
        return quotes.sorted { (symbolOrder[$0.symbol] ?? 99) < (symbolOrder[$1.symbol] ?? 99) }
    }

    private func fetchSingleQuote(symbol: String) async throws -> MarketQuote? {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=1d&range=1d")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chart = json["chart"] as? [String: Any],
              let results = chart["result"] as? [[String: Any]],
              let result = results.first,
              let meta = result["meta"] as? [String: Any],
              let price = meta["regularMarketPrice"] as? Double,
              let prevClose = meta["chartPreviousClose"] as? Double else {
            return nil
        }

        let shortName = meta["shortName"] as? String ?? meta["symbol"] as? String ?? symbol
        let change = price - prevClose
        let changePct = prevClose != 0 ? (change / prevClose) * 100 : 0

        return MarketQuote(
            symbol: symbol,
            name: shortName,
            price: price,
            change: change,
            changePercent: changePct
        )
    }

    // MARK: - Crypto (CoinGecko — no auth required)

    func fetchCryptoPrices() async throws -> [CryptoPrice] {
        let url = URL(string: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,solana&vs_currencies=usd&include_24hr_change=true")!
        let (data, _) = try await session.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: Double]] else {
            return []
        }

        let cryptoNames: [String: (name: String, symbol: String)] = [
            "bitcoin": ("Bitcoin", "BTC"),
            "ethereum": ("Ethereum", "ETH"),
            "solana": ("Solana", "SOL"),
        ]

        return json.compactMap { key, values in
            guard let info = cryptoNames[key],
                  let price = values["usd"],
                  let change = values["usd_24h_change"] else { return nil }

            return CryptoPrice(
                coinId: key,
                symbol: info.symbol,
                name: info.name,
                currentPrice: price,
                priceChangePercentage24h: change
            )
        }
        .sorted { $0.currentPrice > $1.currentPrice }
    }

    // MARK: - Fear & Greed Index (alternative.me — no auth required)

    func fetchFearGreedIndex() async throws -> FearGreedIndex {
        let url = URL(string: "https://api.alternative.me/fng/?limit=1")!
        let (data, _) = try await session.data(from: url)
        let response = try decoder.decode(FearGreedResponse.self, from: data)

        guard let entry = response.data?.first,
              let valueStr = entry.value,
              let value = Int(valueStr),
              let classification = entry.valueClassification else {
            return FearGreedIndex(value: 50, classification: "Neutral")
        }

        return FearGreedIndex(value: value, classification: classification)
    }

    // MARK: - Space Weather (NOAA SWPC — no auth required)

    func fetchSpaceWeather() async throws -> SpaceWeather {
        // Fetch Kp index
        let kpURL = URL(string: "https://services.swpc.noaa.gov/products/noaa-planetary-k-index.json")!
        let (kpData, _) = try await session.data(from: kpURL)
        guard let kpArray = try JSONSerialization.jsonObject(with: kpData) as? [[Any]],
              kpArray.count > 1,
              let lastEntry = kpArray.last,
              lastEntry.count >= 2 else {
            return SpaceWeather(kpIndex: 0, kpCategory: "G0", solarWindSpeed: 0, solarWindDensity: 0, bzComponent: 0, lastUpdate: Date())
        }

        let kpValue: Double
        if let kpStr = lastEntry[1] as? String, let kp = Double(kpStr) {
            kpValue = kp
        } else if let kp = lastEntry[1] as? Double {
            kpValue = kp
        } else {
            kpValue = 0
        }

        // Fetch solar wind plasma
        let plasmaURL = URL(string: "https://services.swpc.noaa.gov/products/solar-wind/plasma-1-day.json")!
        let (plasmaData, _) = try await session.data(from: plasmaURL)
        var windSpeed: Double = 0
        var windDensity: Double = 0
        if let plasmaArray = try JSONSerialization.jsonObject(with: plasmaData) as? [[Any]],
           plasmaArray.count > 1,
           let lastPlasma = plasmaArray.last,
           lastPlasma.count >= 3 {
            if let densStr = lastPlasma[1] as? String, let d = Double(densStr) { windDensity = d }
            if let spdStr = lastPlasma[2] as? String, let s = Double(spdStr) { windSpeed = s }
        }

        // Fetch Bz component
        let magURL = URL(string: "https://services.swpc.noaa.gov/products/solar-wind/mag-1-day.json")!
        let (magData, _) = try await session.data(from: magURL)
        var bz: Double = 0
        if let magArray = try JSONSerialization.jsonObject(with: magData) as? [[Any]],
           magArray.count > 1,
           let lastMag = magArray.last,
           lastMag.count >= 4 {
            if let bzStr = lastMag[3] as? String, let b = Double(bzStr) { bz = b }
        }

        let gScale: String
        switch kpValue {
        case ..<5: gScale = "G0"
        case ..<6: gScale = "G1"
        case ..<7: gScale = "G2"
        case ..<8: gScale = "G3"
        case ..<9: gScale = "G4"
        default:   gScale = "G5"
        }

        return SpaceWeather(kpIndex: kpValue, kpCategory: gScale, solarWindSpeed: windSpeed, solarWindDensity: windDensity, bzComponent: bz, lastUpdate: Date())
    }

    // MARK: - ISS Position (Open Notify — no auth required)

    func fetchISSPosition() async throws -> ISSPosition {
        let url = URL(string: "http://api.open-notify.org/iss-now.json")!
        let (data, _) = try await session.data(from: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let pos = json["iss_position"] as? [String: String],
              let latStr = pos["latitude"], let lat = Double(latStr),
              let lonStr = pos["longitude"], let lon = Double(lonStr) else {
            return ISSPosition(latitude: 0, longitude: 0, timestamp: Date())
        }
        return ISSPosition(latitude: lat, longitude: lon, timestamp: Date())
    }

    // MARK: - Asteroid Close Approaches (JPL SBDB — no auth required)

    func fetchAsteroidApproaches() async throws -> [AsteroidApproach] {
        let url = URL(string: "https://ssd-api.jpl.nasa.gov/cad.api?dist-max=0.05&date-min=now&date-max=now%2B60&sort=dist&limit=10")!
        let (data, _) = try await session.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let fields = json["fields"] as? [String],
              let dataRows = json["data"] as? [[Any]] else {
            return []
        }

        // Build field index map
        var idx: [String: Int] = [:]
        for (i, field) in fields.enumerated() { idx[field] = i }

        return dataRows.compactMap { row in
            guard let desIdx = idx["des"], let cdIdx = idx["cd"],
                  let distIdx = idx["dist"], let vRelIdx = idx["v_rel"] else { return nil }

            let name = row[desIdx] as? String ?? "Unknown"
            let dateStr = row[cdIdx] as? String ?? ""
            let distAU = Double(row[distIdx] as? String ?? "0") ?? 0
            let vRel = Double(row[vRelIdx] as? String ?? "0") ?? 0
            let distLD = distAU * 389.17 // AU to lunar distances
            let distKm = distAU * 149_597_870.7

            return AsteroidApproach(
                id: "\(name)-\(dateStr)",
                name: name,
                closeApproachDate: String(dateStr.prefix(10)),
                missDistanceLunar: distLD,
                missDistanceKm: distKm,
                relativeVelocity: vRel,
                diameterMin: nil,
                diameterMax: nil,
                isPotentiallyHazardous: distLD < 1.0
            )
        }
    }

    // MARK: - NASA EONET Natural Events (no auth required)

    func fetchNaturalEvents() async throws -> [NaturalEvent] {
        let url = URL(string: "https://eonet.gsfc.nasa.gov/api/v3/events?status=open&limit=20")!
        let (data, _) = try await session.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let events = json["events"] as? [[String: Any]] else {
            return []
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()

        return events.compactMap { event in
            guard let id = event["id"] as? String,
                  let title = event["title"] as? String,
                  let categories = event["categories"] as? [[String: Any]],
                  let categoryTitle = categories.first?["title"] as? String else { return nil }

            var lat: Double?
            var lon: Double?
            var eventDate: Date?
            var sourceURL: String?

            if let geometries = event["geometry"] as? [[String: Any]],
               let lastGeo = geometries.last {
                if let coords = lastGeo["coordinates"] as? [Double], coords.count >= 2 {
                    lon = coords[0]
                    lat = coords[1]
                }
                if let dateStr = lastGeo["date"] as? String {
                    eventDate = dateFormatter.date(from: dateStr) ?? fallbackFormatter.date(from: dateStr)
                }
            }

            if let sources = event["sources"] as? [[String: Any]],
               let firstSource = sources.first,
               let srcURL = firstSource["url"] as? String {
                sourceURL = srcURL
            }

            return NaturalEvent(id: id, title: title, category: categoryTitle, date: eventDate, latitude: lat, longitude: lon, sourceURL: sourceURL)
        }
    }

    // MARK: - NWS Severe Weather Alerts (no auth required)

    func fetchWeatherAlerts() async throws -> [WeatherAlert] {
        let url = URL(string: "https://api.weather.gov/alerts/active?severity=Extreme,Severe")!
        var request = URLRequest(url: url)
        request.setValue("SituationRoom/1.0 (contact@example.com)", forHTTPHeaderField: "User-Agent")
        request.setValue("application/geo+json", forHTTPHeaderField: "Accept")

        let (data, _) = try await session.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let features = json["features"] as? [[String: Any]] else {
            return []
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallbackFormatter = ISO8601DateFormatter()

        return features.prefix(20).compactMap { feature in
            guard let props = feature["properties"] as? [String: Any],
                  let id = props["id"] as? String,
                  let event = props["event"] as? String,
                  let severity = props["severity"] as? String else { return nil }

            let headline = props["headline"] as? String ?? event
            let urgency = props["urgency"] as? String ?? "Unknown"
            let areaDesc = props["areaDesc"] as? String ?? ""

            var onset: Date?
            if let onsetStr = props["onset"] as? String {
                onset = dateFormatter.date(from: onsetStr) ?? fallbackFormatter.date(from: onsetStr)
            }
            var expires: Date?
            if let expStr = props["expires"] as? String {
                expires = dateFormatter.date(from: expStr) ?? fallbackFormatter.date(from: expStr)
            }

            return WeatherAlert(
                id: id, event: event, headline: headline,
                severity: severity, urgency: urgency, areaDesc: areaDesc,
                onset: onset, expires: expires
            )
        }
    }

    // MARK: - Recent CVEs (NVD / NIST — no auth required)

    func fetchRecentCVEs() async throws -> [CVEEntry] {
        // Build date range: last 7 days
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let endDate = formatter.string(from: Date())
        let startDate = formatter.string(from: Date().addingTimeInterval(-7 * 86400))

        let urlStr = "https://services.nvd.nist.gov/rest/json/cves/2.0?resultsPerPage=15&pubStartDate=\(startDate)&pubEndDate=\(endDate)&cvssV3Severity=HIGH"
        guard let url = URL(string: urlStr) else { return [] }

        let (data, _) = try await session.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let vulnerabilities = json["vulnerabilities"] as? [[String: Any]] else {
            return []
        }

        return vulnerabilities.prefix(15).compactMap { vuln in
            guard let cve = vuln["cve"] as? [String: Any],
                  let cveId = cve["id"] as? String else { return nil }

            // Get English description
            var summary = "No description available"
            if let descriptions = cve["descriptions"] as? [[String: Any]] {
                if let enDesc = descriptions.first(where: { ($0["lang"] as? String) == "en" }),
                   let value = enDesc["value"] as? String {
                    summary = String(value.prefix(200))
                }
            }

            // Get CVSS score and severity
            var cvssScore: Double?
            var severity = "MEDIUM"
            if let metrics = cve["metrics"] as? [String: Any] {
                for key in ["cvssMetricV31", "cvssMetricV30"] {
                    if let metricList = metrics[key] as? [[String: Any]],
                       let first = metricList.first,
                       let cvssData = first["cvssData"] as? [String: Any] {
                        cvssScore = cvssData["baseScore"] as? Double
                        if let sev = cvssData["baseSeverity"] as? String {
                            severity = sev.uppercased()
                        }
                        break
                    }
                }
            }

            return CVEEntry(id: cveId, summary: summary, severity: severity, publishedDate: nil, cvssScore: cvssScore)
        }
    }

    // MARK: - Sparkline Data (Yahoo Finance v8 chart — intraday)

    func fetchSparklineData(symbols: [String]) async throws -> [String: [Double]] {
        var result: [String: [Double]] = [:]

        try await withThrowingTaskGroup(of: (String, [Double])?.self) { group in
            for symbol in symbols {
                group.addTask {
                    try await self.fetchSingleSparkline(symbol: symbol)
                }
            }
            for try await pair in group {
                if let (symbol, prices) = pair {
                    result[symbol] = prices
                }
            }
        }

        return result
    }

    private func fetchSingleSparkline(symbol: String) async throws -> (String, [Double])? {
        let encoded = symbol.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? symbol
        let url = URL(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(encoded)?interval=5m&range=1d")!
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let chart = json["chart"] as? [String: Any],
              let results = chart["result"] as? [[String: Any]],
              let result = results.first,
              let indicators = result["indicators"] as? [String: Any],
              let quotes = indicators["quote"] as? [[String: Any]],
              let firstQuote = quotes.first,
              let closes = firstQuote["close"] as? [Any] else {
            return nil
        }

        let prices = closes.compactMap { $0 as? Double }
        guard prices.count >= 2 else { return nil }
        return (symbol, prices)
    }

    // MARK: - Flight Tracking (ADSB.lol primary, OpenSky fallback)

    struct FlightPosition: Identifiable {
        let id: String          // ICAO hex address
        let callsign: String    // e.g. "UAL580"
        let registration: String // e.g. "N24736"
        let aircraftType: String // ICAO type e.g. "B738"
        let latitude: Double
        let longitude: Double
        let altitude: Double    // feet (baro)
        let heading: Double     // degrees
        let velocity: Double    // knots (ground speed)
        let originCountry: String
        let distanceNm: Double? // pre-calculated by ADSB.lol radius query
        let isMilitary: Bool
        let category: String    // e.g. "A3" = large aircraft
        let onGround: Bool
    }

    /// Fetch flights within radius of a point using ADSB.lol (primary).
    /// Falls back to OpenSky if ADSB.lol fails.
    func fetchFlightPositions(lat: Double? = nil, lon: Double? = nil) async throws -> [FlightPosition] {
        // Try ADSB.lol first (no auth, no rate limits, richer data)
        if let flights = try? await fetchFromADSBLol(lat: lat, lon: lon), !flights.isEmpty {
            return flights
        }
        // Fallback to OpenSky
        print("[Flights] ADSB.lol failed, falling back to OpenSky")
        return try await fetchFromOpenSky()
    }

    private func fetchFromADSBLol(lat: Double?, lon: Double?) async throws -> [FlightPosition] {
        let urlString: String
        if let lat, let lon {
            // Radius query: 250 nautical miles around user location
            urlString = "https://api.adsb.lol/v2/lat/\(lat)/lon/\(lon)/dist/250"
        } else {
            // No location — use a wide area (CONUS center)
            urlString = "https://api.adsb.lol/v2/lat/39.0/lon/-98.0/dist/500"
        }

        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.setValue("SituationRoom/1.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let aircraft = json["ac"] as? [[String: Any]] else {
            return []
        }

        return aircraft.prefix(800).compactMap { ac -> FlightPosition? in
            guard let hex = ac["hex"] as? String,
                  let lat = ac["lat"] as? Double,
                  let lon = ac["lon"] as? Double else { return nil }

            let altBaro = ac["alt_baro"]
            // alt_baro can be "ground" string or a number
            let altitude: Double
            if let altNum = altBaro as? Double {
                altitude = altNum
            } else if let altInt = altBaro as? Int {
                altitude = Double(altInt)
            } else {
                return nil // On ground or no altitude
            }

            let callsign = (ac["flight"] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
            let registration = (ac["r"] as? String) ?? ""
            let aircraftType = (ac["t"] as? String) ?? ""
            let gs = ac["gs"] as? Double ?? 0
            let track = ac["track"] as? Double ?? ac["calc_track"] as? Double ?? 0
            let distNm = ac["dst"] as? Double
            let dbFlags = ac["dbFlags"] as? Int ?? 0
            let category = (ac["category"] as? String) ?? ""

            return FlightPosition(
                id: hex,
                callsign: callsign,
                registration: registration,
                aircraftType: aircraftType,
                latitude: lat,
                longitude: lon,
                altitude: altitude,
                heading: track,
                velocity: gs,
                originCountry: "",
                distanceNm: distNm,
                isMilitary: dbFlags & 1 != 0,
                category: category,
                onGround: false
            )
        }
    }

    private func fetchFromOpenSky() async throws -> [FlightPosition] {
        let url = URL(string: "https://opensky-network.org/api/states/all?lamin=10&lomin=-170&lamax=70&lomax=60")!
        var request = URLRequest(url: url)
        request.setValue("SituationRoom/1.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let states = json["states"] as? [[Any]] else {
            return []
        }

        return states.prefix(800).compactMap { state -> FlightPosition? in
            guard state.count >= 11,
                  let icao = state[0] as? String,
                  let lon = state[5] as? Double,
                  let lat = state[6] as? Double else { return nil }

            let callsign = (state[1] as? String)?.trimmingCharacters(in: .whitespaces) ?? ""
            let originCountry = (state[2] as? String) ?? ""
            let altitudeMeters = state[7] as? Double ?? 0
            let onGround = state[8] as? Bool ?? false
            let velocityMps = state[9] as? Double ?? 0
            let heading = state[10] as? Double ?? 0

            guard !onGround else { return nil }

            return FlightPosition(
                id: icao,
                callsign: callsign,
                registration: "",
                aircraftType: "",
                latitude: lat,
                longitude: lon,
                altitude: altitudeMeters * 3.28084, // Convert m → ft to match ADSB.lol
                heading: heading,
                velocity: velocityMps * 1.94384, // Convert m/s → knots to match ADSB.lol
                originCountry: originCountry,
                distanceNm: nil,
                isMilitary: false,
                category: "",
                onGround: false
            )
        }
    }

    // MARK: - Satellite Positions (CelesTrak GP data — no auth required)

    struct SatellitePosition: Identifiable {
        let id: String
        let name: String
        let latitude: Double
        let longitude: Double
        let altitude: Double // km
        let group: String
    }

    func fetchSatellitePositions() async throws -> [SatellitePosition] {
        // Fetch active Starlink satellites (GP JSON format includes orbital elements)
        let url = URL(string: "https://celestrak.org/NORAD/elements/gp.php?GROUP=starlink&FORMAT=json&LIMIT=200")!
        var request = URLRequest(url: url)
        request.setValue("SituationRoom/1.0", forHTTPHeaderField: "User-Agent")

        let (data, _) = try await session.data(for: request)
        guard let entries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        let now = Date()
        return entries.prefix(150).compactMap { entry -> SatellitePosition? in
            guard let name = entry["OBJECT_NAME"] as? String,
                  let noradId = entry["NORAD_CAT_ID"] as? Int,
                  let inclination = entry["INCLINATION"] as? Double,
                  let raan = entry["RA_OF_ASC_NODE"] as? Double,
                  let meanAnomaly = entry["MEAN_ANOMALY"] as? Double,
                  let meanMotion = entry["MEAN_MOTION"] as? Double else { return nil }

            // Simplified position from orbital elements (not precise, but visually correct)
            // Mean motion is revs/day, convert to current position
            let epochStr = entry["EPOCH"] as? String ?? ""
            let epochDate = ISO8601DateFormatter().date(from: epochStr) ?? now
            let elapsed = now.timeIntervalSince(epochDate) / 86400.0 // days
            let currentAnomaly = (meanAnomaly + elapsed * meanMotion * 360).truncatingRemainder(dividingBy: 360)

            // Convert to lat/lon approximation
            let argOfPerigee = (entry["ARG_OF_PERICENTER"] as? Double) ?? 0
            let trueAnomaly = currentAnomaly * .pi / 180
            let raanRad = raan * .pi / 180
            let incRad = inclination * .pi / 180
            let argRad = argOfPerigee * .pi / 180

            let lat = asin(sin(incRad) * sin(trueAnomaly + argRad)) * 180 / .pi
            let lon = (atan2(cos(incRad) * sin(trueAnomaly + argRad), cos(trueAnomaly + argRad)) + raanRad) * 180 / .pi
            let normalizedLon = lon.truncatingRemainder(dividingBy: 360)
            let finalLon = normalizedLon > 180 ? normalizedLon - 360 : (normalizedLon < -180 ? normalizedLon + 360 : normalizedLon)

            let altitude = 550.0 // Starlink nominal altitude

            return SatellitePosition(
                id: "\(noradId)",
                name: name,
                latitude: lat,
                longitude: finalLon,
                altitude: altitude,
                group: "Starlink"
            )
        }
    }

    // MARK: - Solar Flare X-ray Flux (NOAA SWPC GOES — no auth required)

    func fetchSolarXrayFlux() async throws -> [(Date, Double)] {
        let url = URL(string: "https://services.swpc.noaa.gov/json/goes/primary/xrays-1-day.json")!
        let (data, _) = try await session.data(from: url)

        guard let entries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            return []
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")

        return entries.compactMap { entry in
            guard let timeTag = entry["time_tag"] as? String,
                  let flux = entry["flux"] as? Double,
                  let date = dateFormatter.date(from: timeTag),
                  flux > 0 else { return nil }
            return (date, flux)
        }
    }

    // MARK: - Aurora Probability (NOAA SWPC OVATION — no auth required)

    func fetchAuroraData() async throws -> [[Int]] {
        let url = URL(string: "https://services.swpc.noaa.gov/json/ovation_aurora_latest.json")!
        let (data, _) = try await session.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let coords = json["coordinates"] as? [[Any]] else {
            return []
        }

        // coords is array of [longitude, latitude, aurora_probability]
        // Build a simplified grid: group by latitude bands for polar projection
        // Return as [[lon, lat, probability]] integers
        return coords.compactMap { entry in
            guard entry.count >= 3,
                  let lon = entry[0] as? Int,
                  let lat = entry[1] as? Int,
                  let prob = entry[2] as? Int,
                  prob > 5 else { return nil } // Only include visible aurora
            return [lon, lat, prob]
        }
    }

    // MARK: - RSS Headlines (direct fetch + parse)

    func fetchRSSHeadlines(from feedURL: String, source: String, category: NewsItem.NewsCategory) async throws -> [NewsItem] {
        guard let url = URL(string: feedURL) else { return [] }
        var request = URLRequest(url: url)
        request.setValue("SituationRoom/1.0", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await session.data(for: request)
        return SimpleRSSParser.parse(data: data, source: source, category: category)
    }
}
