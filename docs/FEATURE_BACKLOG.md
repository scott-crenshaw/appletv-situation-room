# Feature Backlog — Situation Room v2.0

**Created:** 2026-02-20
**Based on:** Research of commercial command centers, OSINT tools, SOC displays, trading floors, NASA Mission Control, and cyberpunk dashboard aesthetics.

## Tier 1: Small (1-2 files, < 100 lines each)

| # | Feature | Coolness | Description | Data Source |
|---|---------|----------|-------------|-------------|
| 1 | **Aurora probability polar map** | ★★★★★ | Glowing green/purple oval over dark polar projection — pure sci-fi | SWPC `ovation_aurora_latest.json` (free, no key) |
| 2 | **Animated rolling number counters** | ★★★★½ | Digits roll like a mechanical ticker when data updates — signals "live" | Existing data, `.contentTransition(.numericText())` |
| 3 | **Sparklines in market/watchlist grids** | ★★★★ | Transforms static numbers into a "wall of trends" — massive data density boost | Yahoo Finance intraday data |
| 4 | **Earthquake expanding rings** | ★★★★ | Concentric circles pulse outward from epicenter, magnitude = size, depth = color | USGS (already integrated) |
| 5 | **Countdown timers** | ★★★½ | Next ISS pass, market open/close, data refresh — adds urgency | Computed from existing data |
| 6 | **Scan line / CRT overlay** | ★★★½ | 1-2px horizontal lines across panels — instant retro-military aesthetic | Pure SwiftUI overlay |
| 7 | **More RSS feeds** | ★★★ | Reuters, AP, NPR, Guardian — broader headline coverage in news ticker | Free RSS |

## Tier 2: Medium (new screen or major component, 2-4 files, 100-300 lines)

| # | Feature | Coolness | Description | Data Source |
|---|---------|----------|-------------|-------------|
| 1 | **Live flight tracking map** | ★★★★★ | Thousands of aircraft moving across dark globe — mesmerizing density | OpenSky Network API (free, no key) |
| 2 | **S&P 500 treemap heatmap** | ★★★★★ | Finviz-style colored blocks, size = market cap, color = daily % change — instantly readable | Yahoo Finance (already integrated) |
| 3 | **Satellite constellation tracker** | ★★★★★ | Glowing orbital arcs wrapping a dark globe — Starlink shell is jaw-dropping | CelesTrak TLEs (free, no key) |
| 4 | **Animated attack arc map** | ★★★★½ | Glowing parabolic lines from attacker to target on dark globe — THE situation room visual | Cloudflare Radar API (free w/ account) |
| 5 | **Lightning strike map** | ★★★★½ | Real-time white flashes on dark map, fading afterglow — dramatic and unpredictable | Blitzortung (free community data) |
| 6 | **Weather radar overlay** | ★★★★ | NEXRAD green/yellow/red reflectivity painted on dark US map — beautiful and practical | Iowa Mesonet WMS tiles (free, no key) |
| 7 | **Radar sweep display** | ★★★★ | Rotating arm illuminating blips that fade — classic command center element | Earthquake/satellite position data |
| 8 | **Ship tracking on strategic straits** | ★★★★ | Vessel density reveals shipping lanes — Hormuz, Malacca, Suez glow with traffic | aisstream.io WebSocket (free key) |
| 9 | **Solar flare X-ray flux chart** | ★★★½ | Glowing line spikes dramatically during flares — real space weather drama | SWPC GOES X-ray data (free, no key) |
| 10 | **Wildfire hotspot map** | ★★★½ | Orange/red dots glowing against dark terrain — ominous and informative | NASA FIRMS API (free w/ registration) |

## Tier 3: Hard (significant architecture, new rendering tech, or complex data)

| # | Feature | Coolness | Description | Data Source |
|---|---------|----------|-------------|-------------|
| 1 | **3D globe with orbital tracks + flight paths** | ★★★★★ | THE ultimate situation room centerpiece — rotating Earth with live data layers | SceneKit + CelesTrak + OpenSky |
| 2 | **Matrix rain driven by real data** | ★★★★½ | Cascading CVE IDs, IP addresses, stock tickers instead of random chars — functional art | Metal/Canvas shader + existing data |
| 3 | **SDR waterfall spectrogram** | ★★★★½ | Scrolling frequency display — signals glow against deep blue — alien aesthetic | Simulated from broadcast schedules |
| 4 | **Correlation matrix heatmap** | ★★★★ | NxN colored grid shows market regime "fingerprint" — pattern changes signal trouble | Yahoo Finance cross-correlation calc |
| 5 | **Network topology / BGP visualization** | ★★★★ | Internet infrastructure as a living graph — nodes pulse, edges glow with traffic | Cloudflare Radar BGP API (free) |
| 6 | **Entity relationship graph** | ★★★½ | Force-directed graph linking threats, actors, CVEs — intelligence analyst feel | NVD + GDELT data |
| 7 | **macOS native target** | ★★★ | Run on Mac as a dedicated window or screensaver — broader audience | Same codebase, new build target |

## API Quick Reference

| API | URL | Key Required | Used By |
|-----|-----|--------------|---------|
| SWPC Aurora | `services.swpc.noaa.gov/json/ovation_aurora_latest.json` | No | Aurora map |
| SWPC GOES X-ray | `services.swpc.noaa.gov/json/goes/primary/xrays-1-day.json` | No | Solar flare chart |
| OpenSky Network | `opensky-network.org/api/states/all` | No (rate limited) | Flight tracking |
| CelesTrak | `celestrak.org/NORAD/elements/gp.php?GROUP=starlink&FORMAT=json` | No | Satellite tracker |
| Cloudflare Radar | `api.cloudflare.com/client/v4/radar/...` | Free account | Attack arcs, BGP |
| Iowa Mesonet NEXRAD | `mesonet.agron.iastate.edu/cgi-bin/wms/nexrad/n0q-t.cgi` | No | Weather radar |
| aisstream.io | `wss://stream.aisstream.io/v0/stream` | Free key | Ship tracking |
| NASA FIRMS | `firms.modaps.eosdis.nasa.gov/api/area/csv/...` | Free key | Wildfire map |
| Blitzortung | Community WebSocket servers | No | Lightning map |
| GreyNoise | `api.greynoise.io/v3/community/{ip}` | Free tier | Cyber threat data |

## Design Principles (from research)

1. **Color discipline** — Near-black background (#0a0a0f), cyan/teal as primary accent, strict alert spectrum (green → yellow → orange → red)
2. **Every pixel earns its place** — No decorative whitespace, aesthetic comes from density and organization
3. **Motion signals life** — Scrolling tickers, pulsing indicators, animated arcs all signal "this is live"
4. **Context over raw numbers** — Show what's normal so deviations are immediately apparent
5. **Animated arcs on dark maps** — The single most iconic situation room visual element
