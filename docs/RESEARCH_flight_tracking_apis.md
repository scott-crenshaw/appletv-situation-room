# Flight Tracking API Research

**Date:** 2026-02-20
**Purpose:** Evaluate flight tracking APIs for tvOS dashboard (replacing/supplementing OpenSky Network)

---

## Summary Comparison Table

| Source | Auth Required | Free Tier | Rate Limit (Free) | Live Position Data | Origin/Dest | Aircraft Type | Cost (Paid) | Protocol |
|--------|--------------|-----------|-------------------|-------------------|-------------|---------------|-------------|----------|
| **OpenSky Network** | Optional (better w/ account) | Yes | 400 credits/day anon; 4,000 auth | Yes (18 fields) | No | Category only | Free (academic) | REST |
| **ADSB.lol** | No (planned future) | Yes | None currently | Yes (ADSBx-compatible) | No | ICAO type code | Free | REST |
| **ADS-B Exchange (RapidAPI)** | API key (RapidAPI) | No | 10,000 req/mo | Yes (rich fields) | No | Reg + ICAO type | $10/mo | REST |
| **FlightRadar24** | API key + subscription | Sandbox only (static data) | N/A | Yes (very rich) | Yes | Yes | $9+/mo | REST |
| **FlightAware AeroAPI** | API key | $5/mo free credit | ~100 queries/mo free | Yes | Yes | Yes | $0.05/query | REST |
| **Aviationstack** | API key | 100 req/mo | 1 req/60s on some endpoints | Limited | Yes | Yes | $49.99/mo+ | REST |
| **AirLabs** | API key | ~1,000 queries/mo | Unknown | Yes | Yes | Yes | $49/mo+ | REST |
| **AeroDataBox** | API key (RapidAPI) | 300-600 calls/mo | Per-plan | Limited | Yes | Yes | $5/mo+ | REST |
| **RadarBox** | API key | No | N/A | Yes | Yes | Yes | $299.95/mo+ | REST |
| **FAA SWIM/TFMS** | Govt agreement | N/A | N/A | US only | Yes | Yes | Free (govt) | JMS |

---

## Detailed Analysis

### 1. OpenSky Network (CURRENT)
**URL:** https://opensky-network.org
**Status:** Active, recently migrated auth to OAuth2

**Authentication:**
- Anonymous access available (limited)
- Free account creation for better limits
- OAuth2 client credentials flow required for accounts created after March 2025
- Legacy accounts still use basic auth (deprecated)

**Rate Limits:**
| Tier | Daily Credits | Time Resolution | Historical Data |
|------|--------------|-----------------|-----------------|
| Anonymous | 400 | 10 seconds | Current only |
| Authenticated | 4,000 | 5 seconds | Up to 1 hour |
| Active Feeder | 8,000 | 5 seconds | Up to 1 hour |
| `/states/own` endpoint | Unlimited | 5 seconds | Current (feeders only) |

**Data Fields (18 per aircraft):**
icao24, callsign, origin_country, time_position, last_contact, longitude, latitude, baro_altitude, on_ground, velocity, true_track, vertical_rate, sensors, geo_altitude, squawk, spi, position_source, category

**What's Missing:** No origin/destination airports, no airline info, no aircraft registration, no aircraft type (only broad category 0-20)

**Coverage:** Global, community-fed. Varies by region (excellent Europe, good North America, sparse elsewhere)

**Reliability:** Generally stable but has had outages. "As is" service with no SLA. Rate limit enforcement can be aggressive.

**Verdict for Dashboard:** Workable for basic "dots on a map" with callsigns. The 400 anonymous credits/day = ~16 requests/hour if polling every 3.75 minutes. With auth (4,000/day) = ~166 requests/hour or roughly one request every 22 seconds. Adequate for a 30-second screen rotation.

---

### 2. ADSB.lol (BEST FREE ALTERNATIVE)
**URL:** https://www.adsb.lol / https://api.adsb.lol
**Status:** Active, community-driven, open source

**Authentication:** None required currently. Future plans to require API key (obtainable by feeding data).

**Rate Limits:** NONE currently. This is the most permissive free option available.

**Data Fields:** ADSBx v2 compatible format including:
- hex (ICAO), registration, ICAO aircraft type code, dbFlags (military/interesting)
- lat/lon, baro_altitude, geo_altitude, ground_speed, track, vertical_rate
- squawk, emergency status, MLAT indicators, signal strength
- Wind calculations, temperature estimates (experimental)

**What's Missing:** No origin/destination airports, no airline name (callsign only)

**Coverage:** Global via community feeders. Unfiltered (shows military, government, LADD aircraft that other services hide).

**Reliability:** Community-run project. No SLA. Could change policies or go down. But actively maintained with GitHub presence.

**Cost:** Completely free. ODbL 1.0 licensed data.

**Protocol:** REST API, drop-in replacement for ADSBx RapidAPI format.

**Verdict for Dashboard:** STRONGEST free option. Richer data than OpenSky (aircraft type, registration), no rate limits, and ADSBx-compatible format. Risk is that it's community-run and may add API key requirements. Worth implementing as primary or fallback.

---

### 3. ADS-B Exchange (via RapidAPI)
**URL:** https://www.adsbexchange.com / RapidAPI
**Status:** Active, moved fully to paid RapidAPI model

**Authentication:** RapidAPI key required (subscription).

**Rate Limits:** 10,000 requests/month on $10/mo plan. No free tier.

**Data Fields:** Very rich (see v2 API fields above). Includes ICAO hex, registration, aircraft type, lat/lon, altitude, speed, heading, squawk, military flags, MLAT, signal strength.

**What's Missing:** No origin/destination airports.

**Coverage:** Global, community-fed. One of the largest ADS-B networks. Unfiltered.

**Reliability:** Stable commercial service backed by RapidAPI infrastructure.

**Cost:** $10/month for 10,000 requests. Enterprise pricing available for commercial use.

**Verdict for Dashboard:** Good data quality but costs money. 10,000 requests/month = ~333/day = ~14/hour. Tight for continuous polling but workable for a dashboard that shows flights for 30 seconds every few minutes.

---

### 4. FlightRadar24 API
**URL:** https://fr24api.flightradar24.com
**Status:** Official API launched ~2024, actively promoted

**Authentication:** FR24 account + paid subscription required. Sandbox (free) uses static/test data only.

**Rate Limits:** Credit-based system. Credits consumed per API call, varying by endpoint.

**Pricing Tiers:**
| Plan | Credits/Month | Price |
|------|--------------|-------|
| Explorer | 30,000 (60,000 promo) | $9/mo |
| Essential | Higher | Higher |
| Advanced | Highest | Highest |

**Data Fields:** The richest dataset available:
- Real-time positions (lat, lon, speed, altitude)
- Flight info (callsign, registration, aircraft type)
- Route info (origin airport, destination airport)
- Airline information
- Historical tracks

**Coverage:** Best in class. 35,000+ receivers globally. Satellite ADS-B coverage for oceanic areas.

**Reliability:** Commercial-grade. FR24 is the most widely used flight tracker.

**Verdict for Dashboard:** Best data richness (includes origin/destination which no free API provides). But $9/mo minimum and credit system means you need to budget carefully. The Explorer plan's 30,000 credits could work if position queries are cheap (need to check per-endpoint credit costs).

---

### 5. FlightAware AeroAPI
**URL:** https://www.flightaware.com/commercial/aeroapi
**Status:** Active, mature commercial API (v3)

**Authentication:** API key required. Free for personal/academic use up to $5/month.

**Rate Limits:** Usage-based ($0.05 per query). Free tier = ~100 queries/month.

**Data Fields:** Very comprehensive:
- Flight status, positions, tracks
- Origin/destination airports
- Aircraft type, airline
- Departure/arrival times (scheduled, estimated, actual)
- Airport delays, weather

**Coverage:** Excellent North America (FAA data integration). Good global via ADS-B and MLAT.

**Reliability:** Enterprise-grade. Used by airlines and airports. Very stable.

**Cost:** $0.05/query. $5/month free allowance = 100 queries free. Commercial: $100/mo base + per-query.

**Verdict for Dashboard:** Too expensive for continuous polling. 100 free queries/month is about 3/day. Best suited for enrichment (look up a specific flight's route) rather than bulk position data. Could pair with a free position source.

---

### 6. Aviationstack
**URL:** https://aviationstack.com
**Status:** Active

**Authentication:** API key required.

**Rate Limits:** Free tier: 100 requests/month. Rate limited to 1 request/60 seconds on some endpoints.

**Data Fields:** Flight status, airline, departure/arrival airports and times, aircraft info. NOT real-time position tracking — primarily schedule/status data.

**Coverage:** Global airline schedules and status data.

**Cost:** Free: 100 req/mo. Basic: $49.99/mo for 10,000 req. Professional: $149.99/mo.

**Verdict for Dashboard:** NOT suitable for live flight tracking. This is a flight schedule/status API, not a position-tracking API. No real-time lat/lon data. Skip for our use case.

---

### 7. AirLabs
**URL:** https://airlabs.co
**Status:** Active

**Authentication:** API key required.

**Rate Limits:** Free: ~1,000 queries/month.

**Data Fields:** Real-time flight positions (lat, lon, altitude, speed, direction), plus airline, aircraft type, departure/arrival airports.

**Coverage:** Global.

**Cost:** Free: 1,000 queries. Developer: $49/mo (25,000). Business: $75/mo. Enterprise: $475/mo.

**Verdict for Dashboard:** Decent free tier (1,000/month = ~33/day). Data includes origin/destination which is valuable. Could supplement a free position source. Worth testing the free tier.

---

### 8. AeroDataBox
**URL:** https://aerodatabox.com
**Status:** Active, available via RapidAPI

**Authentication:** API key (RapidAPI).

**Rate Limits:** Free: 300-600 calls/month.

**Data Fields:** Flight data, airport info, aircraft info, airline routes.

**Cost:** Free: 300-600 calls. Starts at $5/mo for 3,000 calls. Up to $150/mo for 300,000.

**Verdict for Dashboard:** Very limited free tier. More of a reference/lookup API than real-time tracking. Could be useful for enriching flight data (aircraft type lookups) but not for live position tracking.

---

### 9. RadarBox
**URL:** https://www.radarbox.com/api
**Status:** Active, credit-based API

**Authentication:** API key required.

**Rate Limits:** Credit-based. No free tier.

**Cost:** Developer: $299.95/mo (50,000 credits). Enterprise: $999.95/mo (250,000 credits).

**Verdict for Dashboard:** Way too expensive for a personal project. Skip.

---

### 10. FAA SWIM / TFMS
**URL:** https://www.faa.gov/air_traffic/technology/swim
**Status:** Active government system

**Authentication:** Requires formal agreement with FAA. Not a simple API key signup.

**Protocol:** JMS (Java Messaging Service) — not REST. Requires persistent connection infrastructure.

**Data:** Near real-time US air traffic data. Very rich. Includes military (restricted), airline, route data.

**Coverage:** US airspace only.

**Cost:** Free (government data) but requires onboarding process.

**Verdict for Dashboard:** Not practical for a tvOS app. JMS protocol requires server-side infrastructure. US-only. Complex onboarding. Skip.

---

### 11. ADSBHub
**URL:** https://www.adsbhub.org
**Status:** Active, community project

**Authentication:** Requires feeding data to access.

**Data:** Basic ADS-B position data.

**Verdict for Dashboard:** Requires running an ADS-B receiver to access. Not suitable as a standalone API.

---

## Recommendations for Situation Room Dashboard

### Primary Strategy: ADSB.lol (free, no auth, no rate limits)
- Drop-in replacement for ADSBx format
- Rich data fields including aircraft type and registration
- Risk: community project, may add auth requirements

### Fallback: OpenSky Network (free, auth recommended)
- Already implemented
- 4,000 credits/day with free account is adequate
- Less rich data (no aircraft type, no registration)

### Enrichment Layer (optional): AirLabs or FlightAware
- Use sparingly to look up origin/destination for highlighted flights
- AirLabs: 1,000 free queries/month
- FlightAware: ~100 free queries/month

### If Budget Available: FlightRadar24 Explorer ($9/mo)
- Best data richness (origin/destination included)
- Credit system needs careful management
- Would eliminate need for enrichment layer

### Architecture Recommendation
```
Primary: ADSB.lol API (free, rich, no limits)
  |
  +-- Fallback: OpenSky Network (free, auth, limited)
  |
  +-- Optional enrichment: AirLabs free tier
      (origin/destination for featured flights)
```

Poll primary every 15-30 seconds. If primary fails, fall back to OpenSky. Use enrichment API only for "featured flight" callouts on the dashboard.
