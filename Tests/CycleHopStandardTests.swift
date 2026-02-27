import Foundation

// =============================================================================
// CycleHop Standard — Assertion-based Test Runner
// No XCTest — Swift Playground targets don't support .testTarget.
// Run via: Task { await TestSuite.run() } in a #if DEBUG block.
// =============================================================================

#if DEBUG

// MARK: - Lightweight assertion helpers

private var testsPassed = 0
private var testsFailed = 0

func assert(
    _ condition: Bool,
    _ message: String,
    file: String = #fileID,
    line: Int = #line
) {
    if condition {
        testsPassed += 1
    } else {
        testsFailed += 1
        print("FAIL [\(file):\(line)] \(message)")
    }
}

func assertEqual<T: Equatable>(
    _ a: T,
    _ b: T,
    _ message: String,
    file: String = #fileID,
    line: Int = #line
) {
    assert(a == b, "\(message) — expected \(b), got \(a)", file: file, line: line)
}

// MARK: - Test infrastructure

struct TestCase {
    let name: String
    let body: () async throws -> Void
}

struct TestGroup {
    let name: String
    let cases: [TestCase]
}

// MARK: - TestSuite

enum TestSuite {
    static func run() async {
        testsPassed = 0
        testsFailed = 0

        let groups: [TestGroup] = [
            santanderDataMapperTests(),
            geoQueryTests(),
            providerRegistryTests(),
            edgeCaseTests(),
            bookingIntentTests()
        ]

        print("\n=== CycleHop Standard Tests ===")
        for group in groups {
            print("\n-- \(group.name) --")
            for tc in group.cases {
                do {
                    try await tc.body()
                    print("  PASS: \(tc.name)")
                } catch {
                    testsFailed += 1
                    print("  FAIL: \(tc.name) — threw \(error)")
                }
            }
        }

        let total = testsPassed + testsFailed
        print("\n=== Results: \(testsPassed)/\(total) passed ===\n")
        if testsFailed > 0 {
            print("⚠️  \(testsFailed) test(s) FAILED")
        } else {
            print("✓ All tests passed")
        }
    }
}

// MARK: - 1. SantanderDataMapper tests

private func santanderDataMapperTests() -> TestGroup {
    TestGroup(name: "SantanderDataMapper", cases: [
        TestCase(name: "extracts NbBikes correctly") {
            let json = makeTfLJSON(id: "BikePoints_1", name: "Test Station",
                                   props: [("NbBikes","5"),("NbStandardBikes","3"),
                                           ("NbEBikes","2"),("NbDocks","15"),
                                           ("NbEmptyDocks","10"),("Installed","true")])
            let stations = try SantanderDataMapper.decodeAndMap(data: json, systemId: "com.tfl.santander-cycles")
            assertEqual(stations.count, 1, "Should decode 1 station")
            assertEqual(stations[0].availability.totalBikes, 5, "totalBikes")
            assertEqual(stations[0].availability.standardBikes, 3, "standardBikes")
            assertEqual(stations[0].availability.eBikes, 2, "eBikes")
            assertEqual(stations[0].totalDocks, 15, "totalDocks")
            assertEqual(stations[0].availability.emptyDocks, 10, "emptyDocks")
            assertEqual(stations[0].isOperational, true, "isOperational")
        },
        TestCase(name: "defaults missing keys to 0") {
            let json = makeTfLJSON(id: "BikePoints_2", name: "Empty Station", props: [])
            let stations = try SantanderDataMapper.decodeAndMap(data: json, systemId: "com.tfl.santander-cycles")
            assertEqual(stations[0].availability.totalBikes, 0, "totalBikes default")
            assertEqual(stations[0].availability.eBikes, 0, "eBikes default")
        },
        TestCase(name: "Installed=false → isOperational=false") {
            let json = makeTfLJSON(id: "BikePoints_3", name: "Closed", props: [("Installed","false")])
            let stations = try SantanderDataMapper.decodeAndMap(data: json, systemId: "com.tfl.santander-cycles")
            assertEqual(stations[0].isOperational, false, "isOperational should be false")
        },
        TestCase(name: "systemId is prepended to station id") {
            let json = makeTfLJSON(id: "BikePoints_4", name: "Station", props: [])
            let stations = try SantanderDataMapper.decodeAndMap(data: json, systemId: "com.tfl.santander-cycles")
            assertEqual(stations[0].id, "com.tfl.santander-cycles.BikePoints_4", "id format")
        }
    ])
}

// MARK: - 2. Geo-query tests

private func geoQueryTests() -> TestGroup {
    TestGroup(name: "Geo-queries", cases: [
        TestCase(name: "haversineMetres returns plausible distance") {
            // Trafalgar Square to Tower of London: ~4.5 km
            let trafalgar = Coordinate(latitude: 51.5080, longitude: -0.1281)
            let tower = Coordinate(latitude: 51.5081, longitude: -0.0759)
            let dist = haversineMetres(from: trafalgar, to: tower)
            assert(dist > 3_000 && dist < 6_000, "Distance should be ~4.5 km, got \(Int(dist))m")
        },
        TestCase(name: "nearbyStations filters by radius") {
            let provider = SantanderCyclesProvider(useLocalJSON: true)
            let trafalgar = Coordinate(latitude: 51.5080, longitude: -0.1281)
            let nearby = try await provider.nearbyStations(to: trafalgar, radiusMetres: 1_000)
            // All returned stations should be within 1 km
            for s in nearby {
                let dist = haversineMetres(from: trafalgar, to: s.coordinate)
                assert(dist <= 1_000, "Station \(s.name) at \(Int(dist))m should be within 1000m")
            }
        },
        TestCase(name: "nearbyStations returns results sorted nearest-first") {
            let provider = SantanderCyclesProvider(useLocalJSON: true)
            let trafalgar = Coordinate(latitude: 51.5080, longitude: -0.1281)
            let nearby = try await provider.nearbyStations(to: trafalgar, radiusMetres: 5_000)
            let distances = nearby.map { haversineMetres(from: trafalgar, to: $0.coordinate) }
            let sorted = distances.sorted()
            assertEqual(distances, sorted, "Stations should be sorted nearest-first")
        },
        TestCase(name: "stations(in:) respects bounding box") {
            let provider = SantanderCyclesProvider(useLocalJSON: true)
            let bounds = BoundingBox(minLat: 51.48, maxLat: 51.52, minLon: -0.15, maxLon: -0.09)
            let inBox = try await provider.stations(in: bounds)
            for s in inBox {
                assert(bounds.contains(s.coordinate),
                       "Station \(s.name) at (\(s.coordinate.latitude),\(s.coordinate.longitude)) should be in bounds")
            }
        }
    ])
}

// MARK: - 3. ProviderRegistry tests

private func providerRegistryTests() -> TestGroup {
    TestGroup(name: "ProviderRegistry", cases: [
        TestCase(name: "register and retrieve provider") {
            await MainActor.run {
                let registry = ProviderRegistry.shared
                let provider = SantanderCyclesProvider()
                registry.register(provider)
                assert(registry.provider(id: provider.id) != nil, "Provider should be retrievable by id")
            }
        },
        TestCase(name: "unregister removes provider") {
            await MainActor.run {
                let registry = ProviderRegistry.shared
                let provider = SantanderCyclesProvider()
                registry.register(provider)
                registry.unregister(id: provider.id)
                assert(registry.provider(id: provider.id) == nil, "Provider should be removed")
            }
        },
        TestCase(name: "re-registering same id replaces, no duplicate") {
            await MainActor.run {
                let registry = ProviderRegistry.shared
                let p1 = SantanderCyclesProvider()
                let p2 = SantanderCyclesProvider()
                registry.register(p1)
                registry.register(p2)
                let matchingProviders = registry.providers.filter { $0.id == p1.id }
                assertEqual(matchingProviders.count, 1, "Should have exactly 1 provider per id")
            }
        },
        TestCase(name: "fetchAllStations aggregates from registered providers") {
            await MainActor.run {
                let registry = ProviderRegistry.shared
                registry.register(SantanderCyclesProvider(useLocalJSON: true))
            }
            let stations = await ProviderRegistry.shared.fetchAllStations()
            assert(!stations.isEmpty, "fetchAllStations should return stations from registered providers")
        }
    ])
}

// MARK: - 4. Edge cases

private func edgeCaseTests() -> TestGroup {
    TestGroup(name: "Edge cases", cases: [
        TestCase(name: "empty additionalProperties array") {
            let json = makeTfLJSON(id: "BikePoints_99", name: "Ghost Station", props: [])
            let stations = try SantanderDataMapper.decodeAndMap(data: json, systemId: "test")
            let s = stations[0]
            assertEqual(s.availability.totalBikes, 0, "totalBikes")
            assertEqual(s.availability.emptyDocks, 0, "emptyDocks")
            assertEqual(s.isOperational, true, "isOperational defaults to true")
        },
        TestCase(name: "malformed Installed value treated as not operational") {
            let json = makeTfLJSON(id: "BikePoints_100", name: "Weird Station",
                                   props: [("Installed", "yes")])
            let stations = try SantanderDataMapper.decodeAndMap(data: json, systemId: "test")
            // Strict matching: only "true" (case-insensitive) is operational
            // "yes" is not "true", so treated as not operational
            assertEqual(stations[0].isOperational, false, "non-'true' Installed value should be treated as not operational")
        },
        TestCase(name: "all-zero station is valid") {
            let json = makeTfLJSON(id: "BikePoints_101", name: "Zero Station",
                                   props: [("NbBikes","0"),("NbDocks","0"),("NbEmptyDocks","0"),("Installed","true")])
            let stations = try SantanderDataMapper.decodeAndMap(data: json, systemId: "test")
            assertEqual(stations[0].availability.totalBikes, 0, "zero bikes ok")
        },
        TestCase(name: "BoundingBox.contains edge cases") {
            let box = BoundingBox(minLat: 51.0, maxLat: 52.0, minLon: -1.0, maxLon: 0.0)
            assert(box.contains(Coordinate(latitude: 51.0, longitude: -1.0)), "min corner in box")
            assert(box.contains(Coordinate(latitude: 52.0, longitude: 0.0)), "max corner in box")
            assert(!box.contains(Coordinate(latitude: 50.9, longitude: -0.5)), "below min lat")
            assert(!box.contains(Coordinate(latitude: 51.5, longitude: 0.1)), "beyond max lon")
        }
    ])
}

// MARK: - 5. BookingIntent tests

private func bookingIntentTests() -> TestGroup {
    TestGroup(name: "BookingIntent", cases: [
        TestCase(name: "bookingIntent returns non-nil for Santander station") {
            let provider = SantanderCyclesProvider(useLocalJSON: true)
            let stations = try await provider.fetchStations()
            guard let first = stations.first else {
                assert(false, "Need at least one station to test booking intent")
                return
            }
            let intent = try await provider.bookingIntent(for: first)
            assert(intent != nil, "bookingIntent should return non-nil for Santander")
        },
        TestCase(name: "bookingIntent URL scheme is santandercycles://") {
            let provider = SantanderCyclesProvider(useLocalJSON: true)
            let stations = try await provider.fetchStations()
            guard let first = stations.first else { return }
            let intent = try await provider.bookingIntent(for: first)
            guard case .appDeepLink(let url, _) = intent?.method else {
                assert(false, "Expected .appDeepLink method")
                return
            }
            assert(url.scheme == "santandercycles", "URL scheme should be 'santandercycles', got '\(url.scheme ?? "nil")'")
        },
        TestCase(name: "bookingIntent displayName is set") {
            let provider = SantanderCyclesProvider(useLocalJSON: true)
            let stations = try await provider.fetchStations()
            guard let first = stations.first else { return }
            let intent = try await provider.bookingIntent(for: first)
            assert(!(intent?.displayName.isEmpty ?? true), "displayName should not be empty")
        }
    ])
}

// MARK: - JSON factory helper

private func makeTfLJSON(
    id: String,
    name: String,
    lat: Double = 51.5080,
    lon: Double = -0.1281,
    props: [(String, String)]
) -> Data {
    let propsJSON = props.map { key, value in
        """
        {"key":"\(key)","value":"\(value)","modified":"2024-01-15T10:30:00Z"}
        """
    }.joined(separator: ",")

    let json = """
    [{"id":"\(id)","commonName":"\(name)","lat":\(lat),"lon":\(lon),"additionalProperties":[\(propsJSON)]}]
    """
    return Data(json.utf8)
}

#endif
