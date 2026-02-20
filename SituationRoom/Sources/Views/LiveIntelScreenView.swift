import SwiftUI
import AVKit

/// POC Test #2: Video playback on tvOS.
/// Shows a live news stream + webcam grid.
struct LiveIntelScreenView: View {
    @ObservedObject var state: DashboardState

    // Multiple HLS streams — updated Feb 2026
    // DW News and ABC News confirmed working; others are fallback candidates
    private static let streams: [(name: String, url: String)] = [
        ("DW NEWS", "https://dwamdstream104.akamaized.net/hls/live/2015530/dwstream104/index.m3u8"),
        ("ABC NEWS", "https://abcnews-streams.akamaized.net/hls/live/2023565/abcnewshudson6/master_4000.m3u8"),
        ("FRANCE 24", "https://stream.france24.com/f24/mainlive/playlist.m3u8"),
        ("AL JAZEERA", "https://d1cy85syyhvqz5.cloudfront.net/v1/master/7b67fbda7ab859400a821e9aa0deda20ab7ca3d2/aljazeeraLive/AJE/index.m3u8"),
    ]

    var body: some View {
        HStack(spacing: 2) {
            // Left: Main live news feed (France 24)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("LIVE NEWS")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                    Spacer()
                    Text(Self.streams[0].name)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))

                VideoPlayerView(hlsURL: Self.streams[0].url, label: Self.streams[0].name)
            }
            .frame(maxWidth: .infinity)

            // Right: 2x2 grid — more live streams + webcam placeholders
            VStack(spacing: 2) {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("LIVE FEEDS")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.05))

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                    // NASA TV (known good HLS)
                    ZStack(alignment: .bottomLeading) {
                        VideoPlayerView(hlsURL: Self.streams[1].url, label: Self.streams[1].name)
                        streamLabel(Self.streams[1].name)
                    }
                    .aspectRatio(16/9, contentMode: .fit)

                    // Al Jazeera
                    ZStack(alignment: .bottomLeading) {
                        VideoPlayerView(hlsURL: Self.streams[2].url, label: Self.streams[2].name)
                        streamLabel(Self.streams[2].name)
                    }
                    .aspectRatio(16/9, contentMode: .fit)

                    // DW News
                    ZStack(alignment: .bottomLeading) {
                        VideoPlayerView(hlsURL: Self.streams[3].url, label: Self.streams[3].name)
                        streamLabel(Self.streams[3].name)
                    }
                    .aspectRatio(16/9, contentMode: .fit)

                    // Webcam placeholder
                    WebcamCell(city: "JERUSALEM", status: "Live")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func streamLabel(_ name: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(.red).frame(width: 6, height: 6)
            Text(name)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding(8)
        .background(.ultraThinMaterial.opacity(0.7))
        .cornerRadius(4)
        .padding(6)
    }
}

// MARK: - Video Player (AVKit)

struct VideoPlayerView: View {
    let hlsURL: String
    let label: String
    @State private var player: AVPlayer?
    @State private var playerStatus: String = "Connecting..."
    @State private var statusObserver: NSKeyValueObservation?

    init(hlsURL: String, label: String = "") {
        self.hlsURL = hlsURL
        self.label = label
    }

    var body: some View {
        ZStack {
            Color.black

            if let player {
                VideoPlayer(player: player)
            }

            // Overlay status if not playing
            if playerStatus != "Playing" {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(playerStatus)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.gray)
                    if !label.isEmpty {
                        Text(label)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.7))
            }
        }
        .onAppear {
            guard let url = URL(string: hlsURL) else {
                playerStatus = "Invalid URL"
                return
            }
            let avPlayer = AVPlayer(url: url)
            avPlayer.isMuted = true

            // Observe player item status
            statusObserver = avPlayer.currentItem?.observe(\.status, options: [.new]) { item, _ in
                Task { @MainActor in
                    switch item.status {
                    case .readyToPlay:
                        playerStatus = "Playing"
                        avPlayer.play()
                    case .failed:
                        playerStatus = "Stream error: \(item.error?.localizedDescription ?? "unknown")"
                        print("[Video] Failed: \(hlsURL) — \(item.error?.localizedDescription ?? "?")")
                    case .unknown:
                        playerStatus = "Buffering..."
                    @unknown default:
                        break
                    }
                }
            }

            player = avPlayer
            avPlayer.play()
        }
        .onDisappear {
            statusObserver?.invalidate()
            statusObserver = nil
            player?.pause()
            player = nil
        }
    }
}

// MARK: - Webcam Cell (placeholder for POC)

struct WebcamCell: View {
    let city: String
    let status: String

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Placeholder — in production this would be an AVPlayer
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    VStack {
                        Image(systemName: "video.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.3))
                        Text("YouTube stream")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.white.opacity(0.3))
                    }
                )

            // Label overlay
            HStack(spacing: 6) {
                Circle()
                    .fill(.red)
                    .frame(width: 6, height: 6)
                Text(city)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(8)
            .background(.ultraThinMaterial.opacity(0.7))
            .cornerRadius(4)
            .padding(6)
        }
        .aspectRatio(16/9, contentMode: .fit)
    }
}

// MARK: - NASA TV Test (second direct HLS available for POC)

struct NASATVView: View {
    var body: some View {
        VideoPlayerView(hlsURL: "https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8")
    }
}
