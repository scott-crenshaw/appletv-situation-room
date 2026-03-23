import Foundation
import Combine

/// Central state manager for the dashboard.
/// Coordinates data fetching, panel rotation, and refresh cycles.
@MainActor
class DashboardState: ObservableObject {
    // MARK: - Published state

    @Published var currentScreen: DashboardScreen = .situation
    @Published var screenStartedAt: Date = Date()
    @Published var isAutoRotating = true
    @Published var marketQuotes: [MarketQuote] = []
    @Published var cryptoPrices: [CryptoPrice] = []
    @Published var fearGreed: FearGreedIndex?
    @Published var earthquakes: [Earthquake] = []
    @Published var headlines: [NewsItem] = []
    @Published var currentMapRegionIndex = 0
    @Published var isLoading = true
    @Published var lastUpdated = Date()
    @Published var defconLevel = 4 // Default to DEFCON 4

    // Space & Geophysical
    @Published var spaceWeather: SpaceWeather?
    @Published var issPosition: ISSPosition?
    @Published var asteroidApproaches: [AsteroidApproach] = []
    @Published var naturalEvents: [NaturalEvent] = []

    // Space — Aurora, Solar & Satellites
    @Published var auroraData: [[Int]] = [] // [lon, lat, probability]
    @Published var solarXrayFlux: [(Date, Double)] = [] // time, flux
    @Published var satellitePositions: [APIService.SatellitePosition] = []

    // Flight tracking
    @Published var flightPositions: [APIService.FlightPosition] = []
    @Published var globalFlightPositions: [APIService.FlightPosition] = []

    // Location
    let locationManager = LocationManager()

    // Cyber & Infrastructure
    @Published var weatherAlerts: [WeatherAlert] = []
    @Published var recentCVEs: [CVEEntry] = []

    // Deep Markets
    @Published var watchlistQuotes: [MarketQuote] = []
    @Published var sectorQuotes: [MarketQuote] = []
    @Published var sparklineData: [String: [Double]] = [:] // symbol -> intraday prices

    // Gulf Command
    @Published var conflictEvents: [ConflictEvent] = []
    @Published var gulfFlights: [APIService.FlightPosition] = []
    @Published var militarySatellites: [APIService.SatellitePosition] = []

    // MARK: - Configuration

    let autoRotateInterval: TimeInterval = 30 // seconds per screen
    let dataRefreshInterval: TimeInterval = 120 // seconds between API calls
    let mapPanInterval: TimeInterval = 15 // seconds between map region changes

    enum DashboardScreen: String, CaseIterable {
        case situation = "GLOBAL SITUATION"
        case liveIntel = "LIVE INTEL"
        case markets = "MARKETS & ECONOMY"
        case threats = "THREAT ASSESSMENT"
        case space = "SPACE & GEOPHYSICAL"
        case cyber = "CYBER & INFRASTRUCTURE"
        case deepMarkets = "DEEP MARKETS"
        case globalThreats = "GLOBAL THREAT MATRIX"
        case airTraffic = "AIR TRAFFIC MONITOR"
        case gulfCommand = "PERSIAN GULF COMMAND"
    }

    // MARK: - Timers

    private var rotationTimer: Timer?
    private var dataRefreshTimer: Timer?
    private var mapPanTimer: Timer?

    // MARK: - Lifecycle

    func startDashboard() {
        locationManager.requestLocation()
        Task {
            await fetchAllData()
            isLoading = false
        }
        startAutoRotation()
        startDataRefresh()
        startMapPanning()
    }

    func stopDashboard() {
        rotationTimer?.invalidate()
        dataRefreshTimer?.invalidate()
        mapPanTimer?.invalidate()
    }

    // MARK: - Auto Rotation

    /// Duration per screen — air traffic gets double time for local→global transition
    func screenDuration(for screen: DashboardScreen) -> TimeInterval {
        switch screen {
        case .airTraffic, .gulfCommand: return 60
        default: return autoRotateInterval
        }
    }

    private func startAutoRotation() {
        scheduleNextRotation()
    }

    private func scheduleNextRotation() {
        rotationTimer?.invalidate()
        let duration = screenDuration(for: currentScreen)
        rotationTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                if self.isAutoRotating {
                    self.advanceScreen()
                }
                self.scheduleNextRotation()
            }
        }
    }

    func advanceScreen() {
        let screens = DashboardScreen.allCases
        guard let idx = screens.firstIndex(of: currentScreen) else { return }
        let next = screens.index(after: idx)
        currentScreen = next < screens.endIndex ? screens[next] : screens[0]
        screenStartedAt = Date()
    }

    func previousScreen() {
        let screens = DashboardScreen.allCases
        guard let idx = screens.firstIndex(of: currentScreen) else { return }
        if idx > screens.startIndex {
            currentScreen = screens[screens.index(before: idx)]
        } else {
            currentScreen = screens.last!
        }
        screenStartedAt = Date()
    }

    func goToScreen(_ screen: DashboardScreen) {
        currentScreen = screen
        screenStartedAt = Date()
        pauseAutoRotate()
    }

    func navigateForward() {
        advanceScreen()
        pauseAutoRotate()
    }

    func navigateBack() {
        previousScreen()
        pauseAutoRotate()
    }

    private func pauseAutoRotate() {
        isAutoRotating = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.isAutoRotating = true
            self?.scheduleNextRotation()
        }
    }

    // MARK: - Map Panning

    private func startMapPanning() {
        mapPanTimer = Timer.scheduledTimer(withTimeInterval: mapPanInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.currentMapRegionIndex = (self.currentMapRegionIndex + 1) % mapRegions.count
            }
        }
    }

    // MARK: - Data Refresh

    private func startDataRefresh() {
        dataRefreshTimer = Timer.scheduledTimer(withTimeInterval: dataRefreshInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                await self.fetchAllData()
            }
        }
    }

    func fetchAllData() async {
        async let marketTask: () = fetchMarkets()
        async let cryptoTask: () = fetchCrypto()
        async let quakeTask: () = fetchEarthquakes()
        async let newsTask: () = fetchHeadlines()
        async let fgTask: () = fetchFearGreed()
        async let spaceTask: () = fetchSpaceData()
        async let eventsTask: () = fetchNaturalEvents()
        async let cyberTask: () = fetchCyberData()
        async let deepMarketsTask: () = fetchDeepMarkets()
        async let flightsTask: () = fetchFlights()
        async let gulfTask: () = fetchGulfData()

        _ = await (marketTask, cryptoTask, quakeTask, newsTask, fgTask, spaceTask, eventsTask, cyberTask, deepMarketsTask, flightsTask, gulfTask)
        lastUpdated = Date()
    }

    private func fetchMarkets() async {
        let symbols = ["^GSPC", "^DJI", "^IXIC", "^VIX", "GC=F", "CL=F"]
        do {
            marketQuotes = try await APIService.shared.fetchMarketQuotes(symbols: symbols)
        } catch {
            print("[Markets] Error: \(error.localizedDescription)")
        }
    }

    private func fetchCrypto() async {
        do {
            cryptoPrices = try await APIService.shared.fetchCryptoPrices()
        } catch {
            print("[Crypto] Error: \(error.localizedDescription)")
        }
    }

    private func fetchEarthquakes() async {
        do {
            earthquakes = try await APIService.shared.fetchEarthquakes()
        } catch {
            print("[Earthquakes] Error: \(error.localizedDescription)")
        }
    }

    private func fetchFearGreed() async {
        do {
            fearGreed = try await APIService.shared.fetchFearGreedIndex()
        } catch {
            print("[FearGreed] Error: \(error.localizedDescription)")
        }
    }

    private func fetchHeadlines() async {
        // Fetch from a few key RSS feeds directly
        let feeds: [(url: String, source: String, category: NewsItem.NewsCategory)] = [
            ("https://feeds.bbci.co.uk/news/world/rss.xml", "BBC World", .geopolitics),
            ("https://feeds.bbci.co.uk/news/world/middle_east/rss.xml", "BBC Middle East", .geopolitics),
            ("https://www.cnbc.com/id/100003114/device/rss/rss.html", "CNBC", .markets),
            ("https://thediplomat.com/feed/", "The Diplomat", .geopolitics),
            ("https://feeds.npr.org/1001/rss.xml", "NPR", .geopolitics),
            ("https://www.theguardian.com/world/rss", "Guardian", .geopolitics),
            ("https://rss.nytimes.com/services/xml/rss/nyt/World.xml", "NY Times", .geopolitics),
            ("https://feeds.reuters.com/reuters/topNews", "Reuters", .geopolitics),
        ]

        var allItems: [NewsItem] = []
        for feed in feeds {
            do {
                let items = try await APIService.shared.fetchRSSHeadlines(
                    from: feed.url, source: feed.source, category: feed.category
                )
                allItems.append(contentsOf: items)
            } catch {
                print("[RSS] Error fetching \(feed.source): \(error.localizedDescription)")
            }
        }

        // Sort by date, take top 30
        headlines = allItems
            .sorted { ($0.publishedAt ?? .distantPast) > ($1.publishedAt ?? .distantPast) }
            .prefix(30)
            .map { $0 }
    }

    private func fetchSpaceData() async {
        do {
            async let weather = APIService.shared.fetchSpaceWeather()
            async let iss = APIService.shared.fetchISSPosition()
            async let asteroids = APIService.shared.fetchAsteroidApproaches()
            async let aurora = APIService.shared.fetchAuroraData()

            spaceWeather = try await weather
            issPosition = try await iss
            asteroidApproaches = try await asteroids
            auroraData = (try? await aurora) ?? []
            solarXrayFlux = (try? await APIService.shared.fetchSolarXrayFlux()) ?? []
            satellitePositions = (try? await APIService.shared.fetchSatellitePositions()) ?? []
        } catch {
            print("[Space] Error: \(error.localizedDescription)")
        }
    }

    private func fetchNaturalEvents() async {
        do {
            naturalEvents = try await APIService.shared.fetchNaturalEvents()
        } catch {
            print("[Events] Error: \(error.localizedDescription)")
        }
    }

    private func fetchDeepMarkets() async {
        // Key individual stocks
        let watchlist = [
            "AAPL", "MSFT", "GOOGL", "AMZN", "NVDA", "META", "TSLA", "BRK-B",
            "JPM", "V", "UNH", "JNJ", "WMT", "PG", "MA", "HD",
            "BAC", "XOM", "CVX", "LLY", "ABBV", "PFE", "COST", "MRK",
            "AVGO", "TMO", "CRM", "ORCL",
        ]
        // Sector ETFs
        let sectorETFs = [
            "XLK", "XLF", "XLV", "XLE", "XLY", "XLP",
            "XLI", "XLB", "XLRE", "XLU", "XLC", "SMH",
        ]

        do {
            async let watchlistTask = APIService.shared.fetchMarketQuotes(symbols: watchlist)
            async let sectorTask = APIService.shared.fetchMarketQuotes(symbols: sectorETFs)

            watchlistQuotes = try await watchlistTask
            sectorQuotes = try await sectorTask
        } catch {
            print("[DeepMarkets] Error: \(error.localizedDescription)")
        }

        // Sparklines fetched separately so failure doesn't block quotes
        do {
            sparklineData = try await APIService.shared.fetchSparklineData(symbols: Array(watchlist.prefix(12)))
        } catch {
            print("[Sparklines] Error: \(error.localizedDescription)")
        }
    }

    private func fetchCyberData() async {
        do {
            async let alerts = APIService.shared.fetchWeatherAlerts()
            async let cves = APIService.shared.fetchRecentCVEs()

            weatherAlerts = try await alerts
            recentCVEs = try await cves
        } catch {
            print("[Cyber] Error: \(error.localizedDescription)")
        }
    }

    private func fetchFlights() async {
        do {
            let loc = locationManager.userLocation
            async let localTask = APIService.shared.fetchFlightPositions(
                lat: loc?.coordinate.latitude,
                lon: loc?.coordinate.longitude
            )
            async let globalTask = APIService.shared.fetchGlobalFlightPositions()

            flightPositions = try await localTask
            globalFlightPositions = (try? await globalTask) ?? []
        } catch {
            print("[Flights] Error: \(error.localizedDescription)")
        }
    }

    private func fetchGulfData() async {
        async let conflictsTask = APIService.shared.fetchGDELTConflictEvents()
        async let flightsTask = APIService.shared.fetchGulfFlights()
        async let satsTask = APIService.shared.fetchMilitarySatellites()

        conflictEvents = (try? await conflictsTask) ?? []
        gulfFlights = (try? await flightsTask) ?? []
        militarySatellites = (try? await satsTask) ?? []
    }
}
