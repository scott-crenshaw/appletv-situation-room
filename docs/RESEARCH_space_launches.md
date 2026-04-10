# Space Launch API Research

**Date:** 2026-04-01
**Purpose:** Find free, no-auth APIs for upcoming/recent space launches for Situation Room dashboard

---

## RECOMMENDATION

**Use Launch Library 2 (LL2) Dev endpoint** as the primary (and likely only) data source. It is the most comprehensive free space launch API available, providing upcoming and past launches from all providers worldwide, with lat/lon for map plotting, rocket images, mission details, and launch status.

---

## 1. Launch Library 2 (The Space Devs) -- RECOMMENDED

### Endpoints

| Endpoint | URL |
|----------|-----|
| **Production** | `https://ll.thespacedevs.com/2.2.0/` |
| **Development** | `https://lldev.thespacedevs.com/2.2.0/` |

Both serve the same API schema. The dev endpoint has the same data (tested: identical launches, ~202 upcoming) and its own rate limit counter. **Use the dev endpoint for a dashboard.**

### Authentication
**None required.** No API key needed for either endpoint.

### Rate Limits
- **15 requests per hour** (confirmed via `/api-throttle/` endpoint)
- Returns HTTP 429 with `retry-after` header when exceeded
- Prod and dev have **separate rate limit counters** (tested: prod throttled while dev still worked)
- Self-service check: `GET /2.2.0/api-throttle/?format=json` returns:
  ```json
  {
    "your_request_limit": 15,
    "limit_frequency_secs": 3600,
    "current_use": 0,
    "next_use_secs": 0
  }
  ```
- Paid tier (Patreon) available for higher limits

### Key Endpoints

| Endpoint | Description |
|----------|-------------|
| `/launch/upcoming/?limit=N&format=json` | Next N upcoming launches |
| `/launch/previous/?limit=N&format=json` | Recent past launches |
| `/launch/{id}/?format=json` | Single launch detail |
| `/config/launcher/?format=json` | All rocket/vehicle configs (530 total) |
| `/agencies/?format=json` | Launch providers (SpaceX, NASA, etc.) |
| `/pad/?format=json` | Launch pads with lat/lon |
| `/location/?format=json` | Launch sites |
| `/event/upcoming/?format=json` | Upcoming space events |
| `/program/?format=json` | Programs (Artemis, ISS, etc.) |
| `/astronaut/?format=json` | Astronaut database |
| `/api-throttle/?format=json` | Check your rate limit status |

### Response Structure (Launch)

```json
{
  "count": 202,
  "next": "https://lldev.thespacedevs.com/2.2.0/launch/upcoming/?format=json&limit=10&offset=10",
  "previous": null,
  "results": [
    {
      "id": "uuid-string",
      "slug": "sls-block-1-artemis-ii",
      "name": "SLS Block 1 | Artemis II",      // Format: "Rocket | Mission"
      "status": {
        "id": 1,                                 // 1=Go, 2=TBD, 3=Success, 4=Failure, etc.
        "name": "Go for Launch",
        "abbrev": "Go"
      },
      "net": "2026-04-01T22:24:00Z",            // NET = No Earlier Than (ISO 8601)
      "window_start": "2026-04-01T22:24:00Z",
      "window_end": "2026-04-02T00:24:00Z",
      "net_precision": {
        "name": "Second",                        // Second, Minute, Hour, Day, Month
        "abbrev": "SEC"
      },
      "probability": 80,                         // Launch probability %, can be null
      "weather_concerns": "Cumulus Cloud Rule",  // Can be null
      "launch_service_provider": {
        "id": 44,
        "name": "National Aeronautics and Space Administration",
        "type": "Government"                     // Government, Commercial, etc.
      },
      "rocket": {
        "configuration": {
          "name": "Space Launch System (SLS)",
          "family": "Space Launch System",
          "full_name": "Space Launch System Block 1",
          "variant": "Block 1"
        }
      },
      "mission": {
        "name": "Artemis II",
        "description": "First crewed mission...",
        "type": "Human Exploration",             // Communications, Earth Science, etc.
        "orbit": {
          "name": "Lunar flyby",
          "abbrev": "Lunar flyby"
        }
      },
      "pad": {
        "name": "Launch Complex 39B",
        "latitude": "28.62711233",               // STRING, not number
        "longitude": "-80.62101503",             // STRING, not number
        "location": {
          "name": "Kennedy Space Center, FL, USA",
          "country_code": "USA",
          "timezone_name": "America/New_York"
        },
        "map_image": "https://...jpg"
      },
      "image": "https://...jpeg",                // Rocket/mission image URL
      "infographic": "https://...jpeg",          // Can be null
      "webcast_live": true,                      // Is livestream active?
      "program": [{
        "name": "Artemis",
        "image_url": "https://...png"
      }],
      "last_updated": "2026-04-01T16:58:39Z"
    }
  ]
}
```

### Key Data Features
- **Lat/Lon**: YES -- on every pad, as string values
- **Rocket Images**: YES -- `image` field on each launch, plus `config/launcher` has `image_url`
- **Agency Logos**: YES -- via `/agencies/` endpoint, `logo_url` field
- **Mission Descriptions**: YES -- detailed text descriptions
- **Launch Status**: Comprehensive (Go, TBD, TBC, Success, Failure, Partial Failure, In Flight)
- **Weather**: `probability` percentage + `weather_concerns` text
- **Video**: `webcast_live` boolean, mission `vid_urls` array
- **Past Launches**: Same schema, status changes to "Launch Successful" or "Launch Failure"
- **Pagination**: Standard `count`/`next`/`previous` with `limit` and `offset` params
- **Coverage**: ALL providers worldwide (SpaceX, NASA, Roscosmos, ISRO, CNSA, Rocket Lab, etc.)

### Practical Usage for Dashboard
With 15 req/hr limit, the strategy would be:
- Fetch upcoming launches once every 30-60 minutes (`/launch/upcoming/?limit=10`)
- That's 1-2 requests per hour, well within budget
- Cache results in `DashboardState`
- For a launch day, could increase polling but still stay under 15/hr

### Gotchas
- **Lat/lon are strings**, not doubles -- must parse with `Double(latString)`
- **`net` is "No Earlier Than"** -- not a guaranteed launch time
- **`net_precision`** varies: some launches only known to the month
- **Rate limit is per IP**, shared across all apps on the same network
- **Dev endpoint** may occasionally have slightly stale data vs prod, but in testing they were identical

---

## 2. SpaceX API (r-spacex/SpaceX-API) -- STALE DATA, NOT RECOMMENDED

### Base URL
`https://api.spacexdata.com/v4/` (also v5 for some endpoints)

### Authentication
**None required.**

### Current Status: ABANDONED / STALE
- **Latest launch in database: Crew-5, October 5, 2022**
- **"Upcoming" launches are from late 2022** (USSF-44, Starlink 4-36, etc.)
- Data has not been updated in ~3.5 years
- GitHub repo still exists but data is frozen
- The API works technically but returns outdated information

### Endpoints Tested
| Endpoint | Status |
|----------|--------|
| `GET /v4/launches/upcoming` | 200 -- but data from 2022 |
| `GET /v4/launches/latest` | 200 -- Crew-5 (Oct 2022) |
| `GET /v4/launches/past` | 200 -- all historical launches |
| `GET /v4/launchpads` | 200 -- has lat/lon |
| `GET /v4/rockets` | 200 -- detailed specs |
| `POST /v4/launches/query` | 200 -- MongoDB-style query |

### Response Structure (Launch)
```json
{
  "id": "mongo-id",
  "name": "Crew-5",
  "flight_number": 187,
  "date_utc": "2022-10-05T16:00:00.000Z",
  "date_unix": 1664985600,
  "date_local": "2022-10-05T12:00:00-04:00",
  "date_precision": "hour",
  "rocket": "5e9d0d95eda69973a809d1ec",          // ID reference
  "launchpad": "5e9e4502f509094188566f88",         // ID reference
  "success": true,
  "upcoming": false,
  "links": {
    "patch": { "small": "url", "large": "url" },
    "webcast": "https://youtu.be/...",
    "youtube_id": "...",
    "wikipedia": "url",
    "flickr": { "small": [], "original": [] }
  },
  "cores": [{
    "core": "id",
    "flight": 1,
    "reused": false,
    "landing_success": true,
    "landing_type": "ASDS"
  }],
  "crew": ["id1", "id2"],
  "payloads": ["id"],
  "failures": []
}
```

### Data Quality
- **Lat/Lon**: YES -- on `/v4/launchpads` (numeric, not strings)
- **Rocket Images**: YES -- via `/v4/rockets`, `flickr_images` array
- **Detailed Specs**: YES -- height, mass, thrust, cost_per_launch, engines
- **SpaceX Only**: Only covers SpaceX launches, not other providers

### Verdict
**Do not use.** Data is frozen at October 2022. LL2 already includes all SpaceX launches with current data.

---

## 3. RocketLaunch.Live -- LIMITED FREE TIER

### Base URL
`https://fdo.rocketlaunch.live/json/`

### Authentication
- **Free endpoint**: `GET /json/launches/next/5` -- NO auth required
- **All other endpoints**: Require API key (`Authorization: Bearer <key>` or `?key=...`)
- Full API requires paid Premium membership via their website

### Free Tier Limitations
- Only ONE free endpoint: next 5 upcoming launches
- No past launches, no pad details, no companies without auth
- `GET /json/launches` returns 401
- `GET /json/pads` returns `{"errors": ["Valid API key is required."]}`
- `GET /json/companies` returns same auth error

### Response Structure (Free Endpoint)
```json
{
  "valid_auth": false,
  "count": 5,
  "limit": 5,
  "total": 143,
  "last_page": 29,
  "result": [
    {
      "id": 39,
      "name": "Artemis II (EM-2)",
      "provider": { "id": 2, "name": "NASA", "slug": "nasa" },
      "vehicle": { "id": 15, "name": "SLS", "slug": "sls" },
      "pad": {
        "id": 36,
        "name": "LC-39B",
        "location": {
          "name": "Kennedy Space Center",
          "state": "FL",
          "statename": "Florida",
          "country": "United States"
        }
      },
      "win_open": "2026-04-01T22:24Z",
      "t0": null,
      "win_close": null,
      "date_str": "Apr 01",
      "tags": [{"id": 9, "text": "Crewed"}],
      "weather_summary": null,
      "weather_temp": "75.10",
      "weather_condition": "Clear",
      "weather_wind_mph": "11.20",
      "media": [],
      "result": -1,                        // -1=pending, 1=success, 2=failure
      "suborbital": false
    }
  ]
}
```

### Key Data Features
- **Lat/Lon**: NO -- not in the free response
- **Images**: NO -- `media` array is empty in free tier
- **Weather**: YES -- temperature, condition, wind (nice bonus)
- **Coverage**: Multi-provider (NASA, SpaceX, Roscosmos, etc.)
- **Attribution Required**: "Data by RocketLaunch.Live"

### Verdict
**Not recommended.** Only 5 launches, no lat/lon, no images, no past launches. LL2 is strictly superior for free access.

---

## 4. Spaceflight News API (SNAPI) -- COMPLEMENTARY

### Base URL
`https://api.spaceflightnewsapi.net/v4/`

### Authentication
**None required.** Completely free, no rate limits documented.

### What It Provides
- Space news articles from multiple outlets (SpaceNews, NASA, etc.)
- Can filter by LL2 launch ID: `/articles/?launch={ll2-uuid}`
- 33,000+ articles indexed

### Response Structure
```json
{
  "count": 289,
  "results": [{
    "id": 37203,
    "title": "Artemis 2 fueling underway",
    "url": "https://spacenews.com/...",
    "image_url": "https://...",
    "news_site": "SpaceNews",
    "summary": "...",
    "published_at": "2026-04-01T17:29:14Z",
    "launches": [],
    "events": []
  }]
}
```

### Verdict
**Useful as a supplement** -- could show related news articles for upcoming launches. Not a launch data source itself, but pairs well with LL2.

---

## 5. Other APIs Investigated

### Open Notify (ISS)
- `http://api.open-notify.org/iss-now.json` -- ISS current position
- No launch data. Only ISS tracking.
- Already covered by the Satellite Orbits screen.

### Launch Library v1 (launchlibrary.net)
- Returns 301 redirect. Original API is **dead/deprecated**.
- Succeeded by Launch Library 2 (The Space Devs).

---

## Summary Comparison

| Feature | LL2 (Dev) | SpaceX API | RL.Live (Free) | SNAPI |
|---------|-----------|------------|----------------|-------|
| Auth Required | No | No | No (next/5 only) | No |
| Rate Limit | 15/hr | None observed | Unknown | None observed |
| Upcoming Launches | 202 | 18 (stale) | 5 | N/A |
| Past Launches | Yes | Yes (to 2022) | No | N/A |
| All Providers | Yes | SpaceX only | Yes | N/A |
| Lat/Lon | Yes (strings) | Yes (numbers) | No | N/A |
| Rocket Images | Yes | Yes | No | N/A |
| Mission Details | Yes | Basic | Basic | N/A |
| Data Current | Yes (2026) | No (2022) | Yes (2026) | Yes |
| Weather | Yes | No | Yes | N/A |
| Launch Status | Detailed | Basic | Basic | N/A |
| News/Articles | No | No | No | Yes |

---

## Implementation Plan for Dashboard

### Data Source
Use **LL2 Dev endpoint** (`lldev.thespacedevs.com/2.2.0/`)

### API Calls Needed
1. `GET /launch/upcoming/?limit=10&format=json` -- next 10 launches (1 request)
2. `GET /launch/previous/?limit=5&format=json` -- last 5 completed launches (1 request)
3. Total: **2 requests per refresh cycle**, well within 15/hr budget

### Refresh Strategy
- Refresh every 30 minutes (4 requests/hr = 27% of budget)
- On launch day, could refresh every 10 minutes (12 requests/hr = 80% of budget)

### Data Available for Display
- Launch countdown timers (from `net` field)
- Launch site markers on map (from `pad.latitude`/`pad.longitude`)
- Rocket/mission images (from `image` field)
- Provider logos (from agency endpoint, cache at startup)
- Mission descriptions and orbit info
- Launch probability percentage
- Weather concerns
- Webcast availability indicator
- Launch status (Go/TBD/TBC/Success/Failure)
- Historical success rates (from agency data)

### SwiftUI Model Fields Needed
```swift
struct SpaceLaunch: Codable, Identifiable {
    let id: String
    let name: String
    let net: String                    // ISO 8601 date
    let windowStart: String?
    let windowEnd: String?
    let probability: Int?
    let weatherConcerns: String?
    let status: LaunchStatus
    let launchServiceProvider: LaunchProvider
    let rocket: Rocket
    let mission: Mission?
    let pad: LaunchPad
    let image: String?                 // URL
    let webcastLive: Bool
}
```
