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
    body: "Station closed 2–4pm Sunday.",
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
