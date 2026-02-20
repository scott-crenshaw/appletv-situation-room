# Decision Log

## 2026-02-19: Use NVD/NIST for CVE data instead of MITRE or circl.lu
- **What**: Switched CVE data source to `services.nvd.nist.gov/rest/json/cves/2.0`
- **Why**: MITRE cveawg API returns 400 with documented params. circl.lu changed to CSAF format (no longer simple JSON). NVD works reliably with date range + severity filters.
- **Alternatives**: MITRE cveawg (broken), cve.circl.lu (format changed), GitHub Advisory Database (requires auth)

## 2026-02-19: Remove `limit` param from NWS API calls
- **What**: NWS api.weather.gov does not support `limit` query parameter
- **Why**: Returns HTTP 400 "Query parameter limit is not recognized". Instead, fetch all and use `.prefix(20)` in Swift.
- **Alternatives**: None — this is how the NWS API works

## 2026-02-19: Use Yahoo Finance v8 chart endpoint instead of v7 quote
- **What**: Per-symbol chart endpoint at `query1.finance.yahoo.com/v8/finance/chart/`
- **Why**: v7 quote API now requires authentication. v8 chart endpoint still works with a User-Agent header.
- **Alternatives**: Alpha Vantage (requires key), Finnhub (requires key), IEX Cloud (requires key)

## 2026-02-19: Static infrastructure status indicators
- **What**: Infrastructure panel shows hardcoded "OPERATIONAL" for DNS, BGP, CDN, etc.
- **Why**: No free API for real-time internet health monitoring. Cloudflare Radar, Thousandeyes, etc. all require auth. Serves as visual framework for future enhancement.
- **Alternatives**: Could scrape status pages (brittle), use Cloudflare Radar API (requires key)

## 2026-02-19: Resize simulator screenshots to 1920px for context window
- **What**: Apple TV 4K simulator produces 3840x2160 screenshots. Resize to 1920x1080 via `sips --resampleWidth 1920`
- **Why**: Claude context window rejects images >2000px in multi-image requests. 1920px is readable and under the limit.
- **Alternatives**: Crop to specific regions (loses context), use non-retina simulator (not available for tvOS)
