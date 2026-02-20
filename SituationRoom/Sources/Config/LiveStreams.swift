/// Live news channels and webcam feeds from World Monitor
/// For POC: use direct HLS URLs where available, YouTube fallback IDs otherwise

struct LiveChannel: Identifiable {
    let id: String
    let name: String
    let youtubeHandle: String
    let fallbackVideoId: String
    /// Direct HLS URL if available (bypasses YouTube extraction)
    let directHLS: String?
}

struct WebcamFeed: Identifiable {
    let id: String
    let city: String
    let country: String
    let region: WebcamRegion
    let youtubeHandle: String
    let fallbackVideoId: String

    enum WebcamRegion: String, CaseIterable {
        case middleEast = "Middle East"
        case europe = "Europe"
        case americas = "Americas"
        case asia = "Asia"
    }
}

// News channels with 24/7 live streams
// Some have direct HLS endpoints (no YouTube extraction needed)
let liveChannels: [LiveChannel] = [
    LiveChannel(id: "bloomberg", name: "Bloomberg", youtubeHandle: "@Bloomberg", fallbackVideoId: "iEpJwprxDdk", directHLS: nil),
    LiveChannel(id: "sky", name: "Sky News", youtubeHandle: "@SkyNews", fallbackVideoId: "YDvsBbKfLPA", directHLS: nil),
    LiveChannel(id: "dw", name: "DW News", youtubeHandle: "@DWNews", fallbackVideoId: "LuKwFajn37U", directHLS: nil),
    LiveChannel(id: "france24", name: "France 24", youtubeHandle: "@FRANCE24English", fallbackVideoId: "Ap-UM1O9RBU",
                directHLS: "https://stream.france24.com/f24/mainlive/playlist.m3u8"),
    LiveChannel(id: "euronews", name: "Euronews", youtubeHandle: "@euronews", fallbackVideoId: "pykpO5kQJ98", directHLS: nil),
    LiveChannel(id: "aljazeera", name: "Al Jazeera", youtubeHandle: "@AlJazeeraEnglish", fallbackVideoId: "gCNeDWCI0vo", directHLS: nil),
    LiveChannel(id: "cnbc", name: "CNBC", youtubeHandle: "@CNBC", fallbackVideoId: "9NyxcX3rhQs", directHLS: nil),
    LiveChannel(id: "nasa", name: "NASA TV", youtubeHandle: "@NASA", fallbackVideoId: "fO9e9jnhYK8", directHLS: "https://ntv1.akamaized.net/hls/live/2014075/NASA-NTV1-HLS/master.m3u8"),
]

// Webcam feeds — all YouTube-based
let webcamFeeds: [WebcamFeed] = [
    // Middle East
    WebcamFeed(id: "jerusalem", city: "Jerusalem", country: "Israel", region: .middleEast, youtubeHandle: "@TheWesternWall", fallbackVideoId: "UyduhBUpO7Q"),
    WebcamFeed(id: "tehran", city: "Tehran", country: "Iran", region: .middleEast, youtubeHandle: "@IranHDCams", fallbackVideoId: "-zGuR1qVKrU"),
    WebcamFeed(id: "mecca", city: "Mecca", country: "Saudi Arabia", region: .middleEast, youtubeHandle: "@MakkahLive", fallbackVideoId: "DEcpmPUbkDQ"),
    // Europe
    WebcamFeed(id: "kyiv", city: "Kyiv", country: "Ukraine", region: .europe, youtubeHandle: "@DWNews", fallbackVideoId: "-Q7FuPINDjA"),
    WebcamFeed(id: "paris", city: "Paris", country: "France", region: .europe, youtubeHandle: "@PalaisIena", fallbackVideoId: "OzYp4NRZlwQ"),
    WebcamFeed(id: "london", city: "London", country: "UK", region: .europe, youtubeHandle: "@EarthCam", fallbackVideoId: "Lxqcg1qt0XU"),
    // Americas
    WebcamFeed(id: "washington", city: "Washington DC", country: "USA", region: .americas, youtubeHandle: "@AxisCommunications", fallbackVideoId: "1wV9lLe14aU"),
    WebcamFeed(id: "newyork", city: "New York", country: "USA", region: .americas, youtubeHandle: "@EarthCam", fallbackVideoId: "4qyZLflp-sI"),
    // Asia
    WebcamFeed(id: "taipei", city: "Taipei", country: "Taiwan", region: .asia, youtubeHandle: "@JackyWuTaipei", fallbackVideoId: "z_fY1pj1VBw"),
    WebcamFeed(id: "tokyo", city: "Tokyo", country: "Japan", region: .asia, youtubeHandle: "@TokyoLiveCam4K", fallbackVideoId: "4pu9sF5Qssw"),
    WebcamFeed(id: "shanghai", city: "Shanghai", country: "China", region: .asia, youtubeHandle: "@SkylineWebcams", fallbackVideoId: "76EwqI5XZIc"),
]
