# European Electricity API Research

**Date:** 2026-04-10

## Recommendation: Energy Charts API (Fraunhofer ISE)

**Winner for this project.** Free, no auth, JSON, excellent coverage.

### Base URL
`https://api.energy-charts.info`

### Authentication
**None required.** No API key, no registration. Completely open.

### Rate Limits
Undocumented but hit 429 after ~20 rapid requests. Space requests 1-2 seconds apart. For a 30s-rotating dashboard, one batch per rotation is fine.

### Endpoints Tested (all return JSON)

#### 1. Generation by Fuel Type
`GET /public_power?country={cc}`

Returns 15-minute resolution data for current day:
```json
{
  "unix_seconds": [1775772000, ...],
  "production_types": [
    {"name": "Nuclear", "data": [42000.0, ...]},
    {"name": "Wind onshore", "data": [23720.1, ...]},
    {"name": "Solar", "data": [0.0, ...]},
    {"name": "Fossil gas", "data": [7203.6, ...]},
    {"name": "Load", "data": [52130.4, ...]}
  ]
}
```
Values in **MW**. Includes: Nuclear, Wind onshore/offshore, Solar, Fossil gas, Fossil brown coal/lignite, Fossil hard coal, Fossil oil, Hydro (run-of-river, reservoir, pumped), Biomass, Geothermal, Waste, Others, Cross border electricity trading, Load, Residual load, Renewable share of load (%), Renewable share of generation (%).

#### 2. Day-Ahead Prices
`GET /price?bzn={zone}`

Returns 15-minute resolution:
```json
{
  "unix_seconds": [...],
  "price": [85.57, 81.9, ...],
  "unit": "EUR / MWh"
}
```

#### 3. Total Power (includes cross-border)
`GET /total_power?country={cc}`

Same format as public_power, includes "Cross border electricity trading" as net import/export.

#### 4. Installed Capacity
`GET /installed_power?country={cc}`

Historical installed capacity by source.

### Country Codes (all confirmed 200 OK)
| Code | Country |
|------|---------|
| de | Germany |
| fr | France |
| es | Spain |
| it | Italy |
| pl | Poland |
| nl | Netherlands |
| be | Belgium |
| at | Austria |
| ch | Switzerland |
| se | Sweden |
| no | Norway |
| dk | Denmark |
| fi | Finland |
| pt | Portugal |
| ie | Ireland |
| cz | Czech Republic |
| hu | Hungary |
| ro | Romania |
| hr | Croatia |
| sk | Slovakia |
| bg | Bulgaria |
| gr | Greece |
| lu | Luxembourg |
| lt | Lithuania |
| lv | Latvia |
| ee | Estonia |

**GB not available** (400 error).

### Price Bidding Zones (confirmed working)
DE-LU, FR, ES, IT-North, IT-South, IT-Centre-North, IT-Centre-South, IT-Sicily, IT-Sardinia, NO1-NO5, SE1-SE4, PL, AT, BE, NL, CH, DK1, DK2, FI, EE, LT, LV, CZ, SK, HU, RO, BG, GR, HR, SI, PT

**IE not available** (400 error).

### Gotchas
- No CORS headers (`access-control-allow-origin` restricted to energy-charts.info) — but fine for native app
- No documented rate limit headers; got 429 after ~20 rapid-fire requests
- `null` values appear at end of arrays (current period not yet complete)
- Data updates every 15 minutes
- License: CC BY 4.0 (Bundesnetzagentur/SMARD.de)

---

## ENTSO-E Transparency Platform API

### Registration
1. Go to https://transparency.entsoe.eu/ → Register
2. After email verification, request API token from account settings
3. Free for non-commercial use

### Base URL
`https://web-api.tp.entsoe.eu/api`

### Authentication
**Query parameter:** `securityToken={your_token}`

### Format
**XML only** (no JSON option). Complex nested XML with namespaces.

### Key Document Types
- `A44` — Day-ahead prices
- `A65` — Total load
- `A69` — Generation forecast (wind/solar)
- `A71` — Generation per type (actual)
- `A11` — Cross-border flows

### Parameters
```
?documentType=A44
&in_Domain=10YDE-VE-------2   (EIC area code)
&out_Domain=10YDE-VE-------2
&periodStart=202604100000
&periodEnd=202604110000
&securityToken=YOUR_TOKEN
```

### Area Codes (EIC)
| Country | Code |
|---------|------|
| Germany-Luxembourg | 10Y1001A1001A82H |
| France | 10YFR-RTE------C |
| Spain | 10YES-REE------0 |
| Italy North | 10Y1001A1001A73I |
| UK | 10YGB----------A |
| Norway NO1 | 10YNO-1--------2 |
| Sweden SE1 | 10Y1001A1001A44P |
| Poland | 10YPL-AREA-----S |

### Rate Limits
400 requests per minute (free tier).

### Verdict
**Not recommended** for this project. XML parsing in Swift is painful, area codes are unwieldy, and registration required. Energy Charts wraps the same underlying ENTSO-E data in clean JSON.

---

## Electricity Maps API

### Status
**Requires paid API key.** Returns 401 without valid `auth-token` header.

Free tier: "Personal" plan available at https://app.electricitymaps.com — gives carbon intensity only, limited to 1 zone, 100 requests/month. **Too restrictive.**

Paid tiers start at ~$25/month for power breakdown data.

### Verdict
**Not usable** for free dashboard.

---

## Implementation Plan for Situation Room

Use **Energy Charts API** exclusively:
1. Fetch `/public_power` for 8-10 major countries (DE, FR, ES, IT, PL, SE, NO, AT, CH, DK)
2. Fetch `/price?bzn=` for same countries' bidding zones
3. Display: generation mix pie/bar per country, price ticker, renewable % gauge
4. Single batch every 60s (well within rate limits)
5. Cross-border flows from "Cross border electricity trading" field in total_power
