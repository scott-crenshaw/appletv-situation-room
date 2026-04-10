import Foundation
import CoreLocation

// MARK: - Maritime Region

enum MaritimeRegion: Int, CaseIterable {
    case usEastCoast = 0
    case europeMed = 1
    case middleEast = 2
    case asiaPacific = 3
    case usWestCoast = 4

    var name: String {
        switch self {
        case .usEastCoast: return "US EAST COAST & CARIBBEAN"
        case .europeMed:   return "EUROPE & MEDITERRANEAN"
        case .middleEast:  return "MIDDLE EAST & W. INDIA"
        case .asiaPacific: return "EAST ASIA & SE ASIA"
        case .usWestCoast: return "US WEST COAST"
        }
    }

    var boundingBox: (minLat: Double, maxLat: Double, minLon: Double, maxLon: Double) {
        switch self {
        case .usEastCoast: return (10, 45, -85, -60)
        case .europeMed:   return (30, 65, -15, 42)
        case .middleEast:  return (5, 35, 32, 80)
        case .asiaPacific: return (-10, 50, 95, 150)
        case .usWestCoast: return (20, 55, -135, -115)
        }
    }

    var mapCenter: CLLocationCoordinate2D {
        switch self {
        case .usEastCoast: return CLLocationCoordinate2D(latitude: 28, longitude: -72)
        case .europeMed:   return CLLocationCoordinate2D(latitude: 42, longitude: 14)
        case .middleEast:  return CLLocationCoordinate2D(latitude: 20, longitude: 56)
        case .asiaPacific: return CLLocationCoordinate2D(latitude: 20, longitude: 122)
        case .usWestCoast: return CLLocationCoordinate2D(latitude: 37, longitude: -125)
        }
    }

    var mapDistance: Double {
        switch self {
        case .usEastCoast: return 6_000_000
        case .europeMed:   return 5_000_000
        case .middleEast:  return 5_000_000
        case .asiaPacific: return 8_000_000
        case .usWestCoast: return 4_000_000
        }
    }

    func contains(latitude: Double, longitude: Double) -> Bool {
        let bb = boundingBox
        return latitude >= bb.minLat && latitude <= bb.maxLat &&
               longitude >= bb.minLon && longitude <= bb.maxLon
    }

    /// AISStream subscription format: [[lat1, lon1], [lat2, lon2]]
    var aisStreamBox: [[Double]] {
        let bb = boundingBox
        return [[bb.minLat, bb.minLon], [bb.maxLat, bb.maxLon]]
    }
}

// MARK: - Maritime Vessel

struct MaritimeVessel: Identifiable {
    let id: String            // MMSI as string
    let mmsi: Int
    var name: String
    var shipType: Int
    var latitude: Double
    var longitude: Double
    var sog: Double           // Speed over ground (knots)
    var cog: Double           // Course over ground (degrees)
    var heading: Double       // True heading (degrees)
    var navStatus: Int
    var destination: String
    var lastUpdated: Date

    var shipTypeText: String {
        switch shipType {
        case 30: return "FISHING"
        case 35: return "MILITARY"
        case 51: return "SAR"
        case 60...69: return "PASSENGER"
        case 70...79: return "CARGO"
        case 80...89: return "TANKER"
        default: return "OTHER"
        }
    }

    var isMoving: Bool { sog > 0.5 }
}

// MARK: - Maritime Stream Service

/// Connects to AISStream.io WebSocket, accumulates vessel positions across 5 global regions.
@MainActor
class MaritimeStreamService: ObservableObject {
    @Published var vesselsByRegion: [MaritimeRegion: [MaritimeVessel]] = [:]
    @Published var isConnected = false
    @Published var hasAPIKey = false

    private var webSocketTask: URLSessionWebSocketTask?
    private var allVessels: [Int: MaritimeVessel] = [:]   // MMSI -> vessel
    private var receiveTask: Task<Void, Never>?
    private var reconnectTask: Task<Void, Never>?
    private var updateTimer: Timer?

    private let maxVesselsPerRegion = 500
    private let vesselExpirySeconds: TimeInterval = 1800  // 30 minutes

    // MARK: - Lifecycle

    func start() {
        guard let apiKey = loadAPIKey(), !apiKey.isEmpty else {
            hasAPIKey = false
            print("[Maritime] No AISStream API key found in Secrets.plist")
            return
        }
        hasAPIKey = true
        connect(apiKey: apiKey)
        startUpdateTimer()
    }

    func stop() {
        receiveTask?.cancel()
        reconnectTask?.cancel()
        updateTimer?.invalidate()
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    // MARK: - API Key

    private func loadAPIKey() -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = dict["AISStreamAPIKey"] as? String else {
            return nil
        }
        return key
    }

    // MARK: - WebSocket Connection

    private func connect(apiKey: String) {
        webSocketTask?.cancel(with: .goingAway, reason: nil)

        let url = URL(string: "wss://stream.aisstream.io/v0/stream")!
        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()

        // Must send subscription within 3 seconds of connecting
        sendSubscription(apiKey: apiKey)

        receiveTask?.cancel()
        receiveTask = Task { [weak self] in
            await self?.receiveLoop()
        }
    }

    private func sendSubscription(apiKey: String) {
        let boundingBoxes = MaritimeRegion.allCases.map { $0.aisStreamBox }

        let subscription: [String: Any] = [
            "APIKey": apiKey,
            "BoundingBoxes": boundingBoxes,
            "FilterMessageTypes": ["PositionReport", "ShipStaticData"]
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: subscription),
              let string = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(string)) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error {
                    print("[Maritime] Subscription error: \(error)")
                    self.isConnected = false
                } else {
                    self.isConnected = true
                    print("[Maritime] Connected to AISStream — \(MaritimeRegion.allCases.count) regions")
                }
            }
        }
    }

    private func receiveLoop() async {
        guard let webSocketTask else { return }

        while !Task.isCancelled {
            do {
                let message = try await webSocketTask.receive()
                switch message {
                case .string(let text):
                    processMessage(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        processMessage(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                if !Task.isCancelled {
                    print("[Maritime] WebSocket error: \(error)")
                    isConnected = false
                    scheduleReconnect()
                }
                return
            }
        }
    }

    private func scheduleReconnect() {
        reconnectTask?.cancel()
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            guard !Task.isCancelled else { return }
            guard let apiKey = loadAPIKey(), !apiKey.isEmpty else { return }
            print("[Maritime] Reconnecting...")
            connect(apiKey: apiKey)
        }
    }

    // MARK: - Message Processing

    private func processMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let messageType = json["MessageType"] as? String else { return }

        switch messageType {
        case "PositionReport":
            processPositionReport(json)
        case "ShipStaticData":
            processStaticData(json)
        default:
            break
        }
    }

    private func processPositionReport(_ json: [String: Any]) {
        guard let meta = json["MetaData"] as? [String: Any],
              let mmsi = meta["MMSI"] as? Int,
              let lat = meta["latitude"] as? Double,
              let lon = meta["longitude"] as? Double,
              let message = json["Message"] as? [String: Any],
              let report = message["PositionReport"] as? [String: Any] else { return }

        let shipName = (meta["ShipName"] as? String)?
            .trimmingCharacters(in: .whitespaces) ?? "UNKNOWN"
        let sog = report["Sog"] as? Double ?? 0
        let cog = report["Cog"] as? Double ?? 0
        let heading = report["TrueHeading"] as? Double ?? 0
        let navStatus = report["NavigationalStatus"] as? Int ?? 15

        let existing = allVessels[mmsi]

        allVessels[mmsi] = MaritimeVessel(
            id: String(mmsi),
            mmsi: mmsi,
            name: shipName.isEmpty ? (existing?.name ?? "UNKNOWN") : shipName,
            shipType: existing?.shipType ?? 0,
            latitude: lat,
            longitude: lon,
            sog: sog,
            cog: cog,
            heading: heading,
            navStatus: navStatus,
            destination: existing?.destination ?? "",
            lastUpdated: Date()
        )
    }

    private func processStaticData(_ json: [String: Any]) {
        guard let meta = json["MetaData"] as? [String: Any],
              let mmsi = meta["MMSI"] as? Int,
              let message = json["Message"] as? [String: Any],
              let staticData = message["ShipStaticData"] as? [String: Any] else { return }

        let shipType = staticData["Type"] as? Int ?? 0
        let name = (staticData["Name"] as? String)?
            .trimmingCharacters(in: .whitespaces) ?? ""
        let destination = (staticData["Destination"] as? String)?
            .trimmingCharacters(in: .whitespaces) ?? ""

        if var vessel = allVessels[mmsi] {
            if shipType > 0 { vessel.shipType = shipType }
            if !name.isEmpty { vessel.name = name }
            if !destination.isEmpty { vessel.destination = destination }
            vessel.lastUpdated = Date()
            allVessels[mmsi] = vessel
        }
    }

    // MARK: - Periodic Region Rebuild (every 3s — batches SwiftUI updates)

    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildRegions()
            }
        }
    }

    private func rebuildRegions() {
        let cutoff = Date().addingTimeInterval(-vesselExpirySeconds)

        // Expire stale vessels
        allVessels = allVessels.filter { $0.value.lastUpdated >= cutoff }

        // Bucket into regions
        var newRegions: [MaritimeRegion: [MaritimeVessel]] = [:]
        for region in MaritimeRegion.allCases {
            newRegions[region] = []
        }

        for vessel in allVessels.values {
            for region in MaritimeRegion.allCases {
                if region.contains(latitude: vessel.latitude, longitude: vessel.longitude) {
                    if (newRegions[region]?.count ?? 0) < maxVesselsPerRegion {
                        newRegions[region]?.append(vessel)
                    }
                    break
                }
            }
        }

        vesselsByRegion = newRegions
    }

    /// Total vessel count across all regions
    var totalVesselCount: Int {
        allVessels.count
    }
}
