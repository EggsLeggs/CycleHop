# CycleHop Open Standard v1.0

## 1. Overview & Goals

The CycleHop Open Standard defines a common interface for integrating any bike share operator into CycleHop. It aims to:

- Provide a consistent data model regardless of operator, city, or bike type
- Support docked, free-floating, e-bike, cargo, and adaptive bike systems
- Allow offline-first apps using bundled JSON and live-API apps using the same protocol
- Enable multi-city aggregation through a single `ProviderRegistry`

## 2. Terminology

| Term | Definition |
|---|---|
| **Operator** | Company or authority running the bike share scheme (e.g. Transport for London) |
| **System** | A named scheme operated by an operator in a city (e.g. Santander Cycles) |
| **Station** | A physical docking location with one or more docks |
| **Vehicle** | A bike (standard, e-bike, cargo, or adaptive), docked or free-floating |
| **Dock** | A physical slot at a station that holds one vehicle |
| **Trip** | A rental from pickup to drop-off (reserved for future versions) |
| **Booking Intent** | A handoff instruction directing the user to book via app deep link or web URL |

## 3. Units & Conventions

- **Coordinates**: WGS84 decimal degrees (latitude, longitude)
- **Distances**: metres (`Int`)
- **Timestamps**: ISO 8601 UTC strings when in JSON; `Date` in Swift models
- **Availability**: integer counts (never percentages)
- **Country codes**: ISO 3166-1 alpha-2 (e.g. `"GB"`, `"US"`)
- **Timezones**: IANA timezone identifiers (e.g. `"Europe/London"`)
- **Colours**: Hex strings with leading `#` (e.g. `"#E1001A"`)

## 4. Data Models

### 4.1 CycleSystem

Describes the bike share scheme at a system level.

```swift
CycleSystem(
    id: "com.tfl.santander-cycles",   // reverse-domain unique ID
    name: "Santander Cycles",
    city: "London",
    country: "GB",
    operatorName: "Transport for London",
    brandColour: "#E1001A",
    logoURL: nil,
    infoURL: URL(string: "https://santandercycles.co.uk"),
    serviceArea: nil,                  // optional ServiceArea polygon
    timezone: "Europe/London",
    capabilities: ProviderCapabilities(...)
)
```

### 4.2 CycleStation + VehicleAvailability

Represents a single docking point.

```swift
CycleStation(
    id: "com.tfl.santander-cycles.BikePoints_1",
    systemId: "com.tfl.santander-cycles",
    name: "River Street, Clerkenwell",
    coordinate: Coordinate(latitude: 51.529163, longitude: -0.109971),
    address: nil,
    availability: VehicleAvailability(
        totalBikes: 7,
        standardBikes: 5,
        eBikes: 2,
        cargoBikes: 0,
        adaptiveBikes: 0,
        emptyDocks: 12,
        totalDocks: 19
    ),
    totalDocks: 19,
    isOperational: true,
    lastUpdated: Date()
)
```

### 4.3 CycleVehicle (free-floating)

For systems like Lime or Bird that park vehicles outside of docks.

```swift
CycleVehicle(
    id: "vehicle-abc123",
    systemId: "com.lime.london",
    type: .eBike,
    coordinate: Coordinate(latitude: 51.51, longitude: -0.12),
    batteryPercent: 74,
    rangeMetres: 18_000,
    lastUpdated: Date()
)
```

Docked-only providers (e.g. Santander) throw `ProviderError.unsupportedOperation` from `fetchVehicles()`.

### 4.4 CycleAlert

A service alert that may affect one or more stations.

```swift
CycleAlert(
    id: "alert-001",
    systemId: "com.tfl.santander-cycles",
    severity: .warning,
    title: "Planned maintenance",
    body: "Station closed 2-4pm Sunday.",
    affectedStationIds: ["com.tfl.santander-cycles.BikePoints_1"],
    startsAt: Date(),
    endsAt: Date().addingTimeInterval(7200)
)
```

### 4.5 ServiceArea

A polygon geofence bounding the operator's coverage zone.

```swift
ServiceArea(
    polygonCoordinates: [
        Coordinate(latitude: 51.49, longitude: -0.20),
        Coordinate(latitude: 51.54, longitude: -0.20),
        Coordinate(latitude: 51.54, longitude: -0.07),
        Coordinate(latitude: 51.49, longitude: -0.07),
        Coordinate(latitude: 51.49, longitude: -0.20)  // closed ring
    ],
    boundingBox: BoundingBox(minLat: 51.49, maxLat: 51.54, minLon: -0.20, maxLon: -0.07)
)
```

### 4.6 PricingPlan

```swift
PricingPlan(
    id: "santander-casual-30min",
    systemId: "com.tfl.santander-cycles",
    name: "Casual — 30 minutes",
    currency: .gbp,
    price: 1.65,
    isTaxable: false,
    description: "First 30 minutes free with any single journey",
    perMinPrice: nil,
    surgeFactor: 1.0,
    planURL: URL(string: "https://santandercycles.co.uk/pricing")
)
```

### 4.7 BookingIntent

Directs the user to start a rental via native app or website.

```swift
BookingIntent(
    stationId: "com.tfl.santander-cycles.BikePoints_1",
    method: .appDeepLink(
        url: URL(string: "santandercycles://station/BikePoints_1")!,
        webFallback: URL(string: "https://santandercycles.co.uk")!
    ),
    displayName: "Open in Santander Cycles"
)
```

## 5. Capability Flags (ProviderCapabilities)

| Flag | Type | Meaning |
|---|---|---|
| `hasDocking` | Bool | System has physical docking stations |
| `hasFreeFloating` | Bool | Vehicles can be parked outside docks |
| `hasEBikes` | Bool | Fleet includes electric-assist bikes |
| `hasCargoBikes` | Bool | Fleet includes cargo / long-tail bikes |
| `hasAdaptiveBikes` | Bool | Fleet includes adaptive / accessible bikes |
| `hasRealtimeAvailability` | Bool | Availability counts are live (not cached/estimated) |
| `supportsReservations` | Bool | Users can reserve a bike in advance |
| `supportsInAppBooking` | Bool | Future: in-app rental flow (always false in v1) |
| `requiresAuthentication` | Bool | API requests require an API key or OAuth token |
| `dataSource` | DataSource | `.bundledJSON`, `.liveAPI`, or `.hybrid` |

## 6. Provider Protocol (BikeShareProvider)

### Required methods

```swift
func fetchSystem() async throws -> CycleSystem
func fetchStations() async throws -> [CycleStation]
func nearbyStations(to coordinate: Coordinate, radiusMetres: Int) async throws -> [CycleStation]
func stations(in bounds: BoundingBox) async throws -> [CycleStation]
```

### Optional methods (default implementations provided)

```swift
func fetchVehicles() async throws -> [CycleVehicle]   // throws .unsupportedOperation by default
func fetchAlerts() async throws -> [CycleAlert]        // returns [] by default
func fetchPricingPlans() async throws -> [PricingPlan] // returns [] by default
func bookingIntent(for station: CycleStation) async throws -> BookingIntent? // returns nil by default
```

Providers that override `fetchStations()` inherit client-side filtering implementations of `nearbyStations` and `stations(in:)` for free.

## 7. Error Types (ProviderError)

| Case | When to throw |
|---|---|
| `.networkUnavailable` | No internet connection |
| `.dataNotFound` | Bundled JSON missing from bundle |
| `.decodingFailed(underlying:)` | JSON schema mismatch |
| `.unauthorized` | API key missing or invalid |
| `.rateLimited(retryAfter:)` | HTTP 429; include `Retry-After` if available |
| `.unsupportedOperation(String)` | Caller invoked a method the provider doesn't support |
| `.providerUnavailable(String)` | Service outage or unexpected HTTP status |

## 8. Caching Policy

Providers are responsible for their own caching. Recommended TTLs:

| Data | Recommended TTL |
|---|---|
| Station availability | 60 seconds |
| Free-floating vehicles | 30 seconds |
| System info | 24 hours |
| Pricing plans | 24 hours |
| Service alerts | 5 minutes |

Providers declare their `dataSource` capability so clients can adjust expectations.

## 9. Booking Intent System

### AppDeepLink

The preferred method. Providers construct a URL using their app's registered scheme, with a web fallback for users without the app installed.

```
santandercycles://station/BikePoints_1
↓ fallback if app not installed
https://santandercycles.co.uk
```

### WebOnly

For providers without a native app or an undocumented URL scheme.

### Future

In-app booking (`.inApp`) is reserved for a future version and not implemented in v1.

## 10. Versioning

This is **v1.0** of the CycleHop Open Standard. Breaking changes will increment the major version. Additive changes (new optional protocol methods, new model fields) increment the minor version. Providers should guard against unknown fields gracefully.

## 11. Real-World Diversity Notes

The standard is designed to handle diverse real-world systems:

| System Type | Examples | Notes |
|---|---|---|
| Docked only | Santander Cycles (London), Citi Bike (NYC) | `hasFreeFloating: false`, `fetchVehicles` not supported |
| Free-floating only | Lime, Bird, Bolt | `hasDocking: false`, no `CycleStation` docks |
| Hybrid | Some Lime markets | Both docking and free-floating |
| E-bike heavy | Santander (new fleet), Lime | `hasEBikes: true`, `eBikes` count in availability |
| Cargo bikes | Onbici (Barcelona) | `hasCargoBikes: true` |
| Adaptive | Some TfL/local authority schemes | `hasAdaptiveBikes: true` |
| No public API | Many municipal systems | Use `.bundledJSON` data source with a JSON snapshot |

Providers with no public API should use `dataSource: .bundledJSON` and document their snapshot date in their config file.

## 12. City Art & Brand Colours

Each city provider can supply an SVG illustration shown on the onboarding city-select card and used as the branded splash art throughout the app. `CityArtView` renders the SVG inside a `WKWebView` using a small HTML wrapper that applies CSS to make the artwork adapt to light/dark mode and respond to the provider's brand colour automatically — no changes to `CityArtView.swift` are needed when adding a new city.

### 12.1 File naming and location

Place the SVG in `Resources/` and name it after the city with no spaces:

```
Resources/London.svg
Resources/NewYork.svg
```

Return the filename (without extension) from `OnboardingCityProvider.cityArtSVGName`:

```swift
public var cityArtSVGName: String? { "NewYork" }
```

### 12.2 SVG structure requirements

The SVG must follow these conventions so the `CityArtView` CSS rules apply correctly:

| Element | Required attribute(s) | Purpose |
|---|---|---|
| Background rect | `fill="white"` | Becomes `Canvas` colour in dark mode |
| City-skyline fill path | `fill="white" id="city-skyline"` | Receives the brand colour on selection; matches background when unselected |
| All stroke paths | `stroke="black"` | Becomes `CanvasText` in dark mode |

The critical requirement is the **city-skyline path**. This is the large filled shape that defines the city silhouette (buildings, skyline, land mass). It must carry both `fill="white"` **and** `id="city-skyline"`:

```xml
<!-- Correct -->
<path d="M413 -6.5L..." fill="white" id="city-skyline"/>

<!-- Wrong — hardcoded colour, will not adapt -->
<path d="M413 -6.5L..." fill="#271A88"/>
```

If you receive an SVG from a designer with a hardcoded fill on the skyline path, replace just that attribute:

```
fill="#______"  →  fill="white" id="city-skyline"
```

Leave all other attributes (`d`, `stroke`, `stroke-width`, etc.) unchanged.

### 12.3 How the CSS rules work

`CityArtView.buildHTML` injects a `<style>` block with four rules:

```css
/* White fills → system Canvas (white in light, ~black in dark) */
path[fill="white"]  { fill: Canvas; }
rect[fill="white"]  { fill: Canvas; }

/* Black strokes → system CanvasText (black in light, white in dark) */
path[stroke="black"] { stroke: CanvasText; }

/* Selected state: brand colour injected at runtime via JS */
#city-skyline { fill: <brandHex>; }
```

The selected-state rule is applied by JavaScript only when the card is in the selected state, so the unselected card shows the skyline blending into the card background (both `Canvas`), and the selected card shows the skyline filled with the provider's `brandColour`.

### 12.4 Brand colour

Set `brandColour` in the provider's config file as a `#RRGGBB` hex string. Use the operator's official primary colour:

```swift
static let brandColour = "#003B70"   // Citi Bike navy
static let brandColour = "#E5362C"   // Santander red
```

Return it from `OnboardingCityProvider.brandColor` as a SwiftUI `Color`, with a safe fallback:

```swift
public var brandColor: Color { Color(hex: CitiBikeConfig.brandColour) ?? .blue }
public var brandForegroundColor: Color { .white }   // text/icon colour drawn on top of brandColor
```

Choose `brandForegroundColor` (`.white` or `.black`) based on which passes WCAG AA contrast against `brandColor`.

## 13. City Stamps

Each city provider can supply a postage-stamp style SVG illustration. Stamps are shown above the "Collect City Stamps" heading on the onboarding about screen — left-aligned, at 72 pt tall, with 50% opacity. Unlike city art (which renders inside a `WKWebView` with CSS), stamps are snapshot-rendered via `SVGLoader` and therefore require both an SVG source and pre-rendered PNG fallbacks.

### 13.1 File naming and location

Place all three files in `Resources/`:

```
Resources/LondonStamp.svg
Resources/LondonStampLight.png   ← rendered for light mode
Resources/LondonStampDark.png    ← rendered for dark mode
```

The naming pattern is `{City}Stamp` where `{City}` matches the city name with no spaces (same convention as city art).

Return the base name (without extension) from `OnboardingCityProvider.stampSVGName`:

```swift
public var stampSVGName: String? { "LondonStamp" }
```

Return `nil` (the default) if no stamp is available for a provider.

### 13.2 SVG structure requirements

Stamp SVGs use a simpler colouring model than city art — there is no CSS injection or `id` convention. The only requirement is that all drawn elements use `stroke="black"` and/or `fill="black"` so that the dark-mode inversion pass (see §13.4) can flip them to white:

| Element | Required attribute | Purpose |
|---|---|---|
| All stroke lines | `stroke="black"` | Inverted to `white` in dark mode |
| All filled shapes | `fill="black"` | Inverted to `white` in dark mode |

Do **not** use hardcoded colours other than black on drawn elements. `fill="white"` may appear inside `<mask>` and `<clipPath>` definitions — these are not visible drawn shapes and are left unchanged by the inversion pass.

### 13.3 PNG fallbacks

Pre-render each stamp SVG at **2× its natural pixel dimensions** (or higher) and export two PNGs — one for each appearance mode. The light PNG uses black line art on a white background; the dark PNG uses white line art on a black background.

Swift Playgrounds may not fire the `WKWebView` snapshot completion handler, so the PNG is always set first and the SVG render is treated as an optional upgrade. If the SVG render fails or never completes, the PNG remains visible.

### 13.4 How dark/light rendering works

`CitySelectScreen.loadStampImage()` applies the following steps at appear time and whenever `colorScheme` changes:

1. **PNG fallback** — sets `stampImage` immediately from `{Name}Light.png` or `{Name}Dark.png`.
2. **SVG load** — reads the SVG from the bundle and replaces the fixed `width`/`height` attributes with `100%`/`100%` so it fills the render viewport.
3. **Background injection** — inserts `<rect width="100%" height="100%" fill="#FFFFFF"/>` (light) or `fill="#000000"` (dark) as the first child of `<svg>` to produce an opaque snapshot.
4. **Colour inversion** (dark mode only) — replaces all `stroke="black"` with `stroke="white"` and all `fill="black"` with `fill="white"` so line art appears white on the black background.
5. **SVG render** — passes the modified SVG to `SVGLoader` at 3× the natural pixel dimensions for sharp rendering at any display scale. If the render succeeds, `stampImage` is upgraded from the PNG to the crisp SVG snapshot.
