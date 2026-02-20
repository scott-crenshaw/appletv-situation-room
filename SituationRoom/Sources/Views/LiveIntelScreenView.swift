import SwiftUI
import AVKit

/// Screen 2: Live Intel — live news streams and webcam grid.
struct LiveIntelScreenView: View {
    @ObservedObject var state: DashboardState

    // Live HLS streams — verified Feb 2026
    private static let streams: [(name: String, url: String)] = [
        ("NBC NEWS NOW", "https://dai.google.com/linear/hls/event/Sid4xiTQTkCT1SLu6rjUSQ/master.m3u8"),
        ("BLOOMBERG", "https://www.bloomberg.com/media-manifest/streams/us.m3u8"),
        ("NEWSMAX", "https://nmxlive.akamaized.net/hls/live/529965/Live_1/index.m3u8"),
        ("SKY NEWS AU", "https://skynewsau-live.akamaized.net/hls/live/2002689/skynewsau-extra1/master.m3u8"),
        ("DW NEWS", "https://dwamdstream104.akamaized.net/hls/live/2015530/dwstream104/index.m3u8"),
    ]

    var body: some View {
        HStack(spacing: 2) {
            // Left: Main live news feed (ABC News)
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

            // Right: 2x2 grid — Bloomberg, Newsmax, Sky News AU, DW News
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
                    ForEach(1..<Self.streams.count, id: \.self) { index in
                        ZStack(alignment: .bottomLeading) {
                            VideoPlayerView(hlsURL: Self.streams[index].url, label: Self.streams[index].name)
                            streamLabel(Self.streams[index].name)
                        }
                        .aspectRatio(16/9, contentMode: .fit)
                    }
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

