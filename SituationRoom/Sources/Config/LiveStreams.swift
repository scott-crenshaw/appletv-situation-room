/// Live news channel configuration
/// All streams use direct HLS URLs playable by AVPlayer — no API keys required

struct LiveStream: Identifiable {
    let id: String
    let name: String
    let hlsURL: String
}

// Verified working Feb 2026 — 3 US, 2 international
let liveStreams: [LiveStream] = [
    LiveStream(id: "nbc", name: "NBC NEWS NOW",
               hlsURL: "https://dai.google.com/linear/hls/event/Sid4xiTQTkCT1SLu6rjUSQ/master.m3u8"),
    LiveStream(id: "bloomberg", name: "BLOOMBERG",
               hlsURL: "https://www.bloomberg.com/media-manifest/streams/us.m3u8"),
    LiveStream(id: "newsmax", name: "NEWSMAX",
               hlsURL: "https://nmxlive.akamaized.net/hls/live/529965/Live_1/index.m3u8"),
    LiveStream(id: "skynewsau", name: "SKY NEWS AU",
               hlsURL: "https://skynewsau-live.akamaized.net/hls/live/2002689/skynewsau-extra1/master.m3u8"),
    LiveStream(id: "dw", name: "DW NEWS",
               hlsURL: "https://dwamdstream104.akamaized.net/hls/live/2015530/dwstream104/index.m3u8"),
]
