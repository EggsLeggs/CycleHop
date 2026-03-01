import SwiftUI
import MapKit

/// Root map and bottom sheet UI. Shows bike points, search, and stamp discovery for the selected provider.
struct ContentView: View {
    let selectedProviderID: String?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var bikePointService: BikePointService
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()
    @StateObject private var searchHistoryStore = SearchHistoryStore()
    @StateObject private var networkMonitor = NetworkMonitor()

    @EnvironmentObject private var stampStore: StampStore

    @State private var selectedBikePoint: BikePoint? = nil
    @State private var sheetMode: SheetMode = .search
    @State private var searchText: String = ""
    @State private var destinationCoordinate: CLLocationCoordinate2D? = nil
    @State private var cameraPosition: MapCameraPosition
    @State private var mapCameraCenter: CLLocationCoordinate2D? = nil
    @State private var nearbyStamps: [StampDefinition] = []
    @State private var showStampClaimSheet = false
    @State private var selectedDetent: PresentationDetent = .height(90)
    @State private var midDetentHeight: CGFloat = 384
    @State private var hasMovedCamera = false
    @AppStorage("hasSeenDebugTooltip") private var hasSeenDebugTooltip = false
    @AppStorage("locationChangeTrigger") private var locationChangeTrigger = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("useOfflineMap") private var useOfflineMap = true
    @State private var showDebugTooltip = false
    @State private var showDebugMenu = false
    @State private var showProfilePanel = false
    @ScaledMetric(relativeTo: .body) private var toolbarIconSize: CGFloat = 16

    // City-switch suggestion (Issue 1)
    @AppStorage("selectedProviderID") private var storedProviderID = ""
    @State private var showCitySwitchAlert = false
    @State private var suggestedProviderID: String? = nil
    @State private var suggestedCityName: String? = nil
    @State private var suggestedSystemName: String? = nil
    @State private var hasSuggestedCitySwitch = false

    private let initialCenter: CLLocationCoordinate2D

    init(selectedProviderID: String? = nil) {
        self.selectedProviderID = selectedProviderID
        _bikePointService = StateObject(wrappedValue: BikePointService(providerID: selectedProviderID))

        let center: CLLocationCoordinate2D
        if let id = selectedProviderID,
           let provider = ProviderRegistry.shared.provider(id: id) as? any OnboardingCityProvider {
            center = CLLocationCoordinate2D(
                latitude: provider.defaultCenter.latitude,
                longitude: provider.defaultCenter.longitude
            )
        } else {
            center = CLLocationCoordinate2D(latitude: 51.509, longitude: -0.118)
        }

        self.initialCenter = center
        _cameraPosition = State(wrappedValue: .region(
            MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        ))
    }

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    private var collapsedDetent: PresentationDetent { .height(90) }

    private var midDetent: PresentationDetent {
        .height(midDetentHeight)
    }

    private var filteredBikePoints: [BikePoint] {
        let center = mapCameraCenter ?? initialCenter
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        return bikePointService.bikePoints
            .sorted { a, b in
                let distA = CLLocation(latitude: a.lat, longitude: a.lon).distance(from: centerLocation)
                let distB = CLLocation(latitude: b.lat, longitude: b.lon).distance(from: centerLocation)
                return distA < distB
            }
            .prefix(75)
            .map { $0 }
    }

    private var bottomSheetContent: some View {
        BottomSheetView(
            sheetMode: $sheetMode,
            searchText: $searchText,
            selectedBikePoint: $selectedBikePoint,
            destinationCoordinate: $destinationCoordinate,
            cameraPosition: $cameraPosition,
            selectedDetent: $selectedDetent,
            showStampClaimSheet: $showStampClaimSheet,
            showProfilePanel: $showProfilePanel,
            isCompact: isCompact,
            nearbyStamps: nearbyStamps,
            midDetent: midDetent,
            collapsedDetent: collapsedDetent,
            bikePointService: bikePointService,
            locationManager: locationManager,
            searchCompleter: searchCompleter,
            stampStore: stampStore,
            searchHistoryStore: searchHistoryStore,
            networkMonitor: networkMonitor
        )
    }

    var body: some View {
        Group {
            if isCompact {
                compactLayout
            } else {
                regularLayout
            }
        }
        .onChange(of: locationManager.userLocation) { _, newLocation in
            updateNearbyStamps(location: newLocation)
            searchCompleter.updateRegion(cityCenter: initialCenter,
                                         userLocation: newLocation)
            checkCitySuggestion(for: newLocation)
        }
        .onChange(of: stampStore.allDefinitions) { _, _ in
            updateNearbyStamps(location: locationManager.userLocation)
        }
        .onChange(of: stampStore.claimedStamps) { _, _ in
            updateNearbyStamps(location: locationManager.userLocation)
        }
        .onChange(of: storedProviderID) { _, newProviderID in
            guard !newProviderID.isEmpty else { return }

            // Reload bike data for the new city without recreating the view.
            Task { await bikePointService.reload(for: newProviderID) }

            // Move camera to new city centre and update filtering origin.
            if let provider = ProviderRegistry.shared.provider(id: newProviderID) as? any OnboardingCityProvider {
                let center = CLLocationCoordinate2D(
                    latitude: provider.defaultCenter.latitude,
                    longitude: provider.defaultCenter.longitude
                )
                mapCameraCenter = center
                withAnimation {
                    cameraPosition = .region(MKCoordinateRegion(
                        center: center,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    ))
                }
                searchCompleter.updateRegion(cityCenter: center,
                                             userLocation: locationManager.userLocation)
            }

            // Collapse the sheet back to search mode.
            selectedBikePoint = nil
            sheetMode = .search
            selectedDetent = collapsedDetent
        }
        .onChange(of: locationChangeTrigger) { _, _ in
            guard let id = selectedProviderID,
                  let provider = ProviderRegistry.shared.provider(id: id) as? any OnboardingCityProvider else { return }
            let center = CLLocationCoordinate2D(
                latitude: provider.defaultCenter.latitude,
                longitude: provider.defaultCenter.longitude
            )
            withAnimation {
                cameraPosition = .region(MKCoordinateRegion(
                    center: center,
                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                ))
            }
            searchCompleter.updateRegion(cityCenter: center,
                                         userLocation: locationManager.userLocation)
        }
        .onChange(of: hasSeenDebugTooltip) { _, newValue in
            if !newValue && !showDebugTooltip {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    withAnimation(.spring(duration: 0.4)) {
                        showDebugTooltip = true
                    }
                }
            }
        }
        .onAppear {
            updateNearbyStamps(location: locationManager.userLocation)
            searchCompleter.updateRegion(cityCenter: initialCenter,
                                         userLocation: locationManager.userLocation)
        }
    }

    private var compactLayout: some View {
        GeometryReader { geometry in
            ZStack {
                mapView
                    .sheet(isPresented: $showStampClaimSheet) {
                        StampClaimSheet(stamps: nearbyStamps)
                            .environmentObject(stampStore)
                    }

                floatingToolbar

                // Stamp pill above collapsed sheet when panel is at minimum height
                VStack {
                    Spacer()
                    if !nearbyStamps.isEmpty && selectedDetent == collapsedDetent {
                        StampPill(nearbyStamps: nearbyStamps) {
                            showStampClaimSheet = true
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.bottom, 90)
                .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: !nearbyStamps.isEmpty && selectedDetent == collapsedDetent)
            }
            .onAppear {
                midDetentHeight = min(350 + geometry.safeAreaInsets.bottom, geometry.size.height)
            }
            .sheet(isPresented: .constant(true)) {
                bottomSheetContent
                    .presentationDetents([collapsedDetent, midDetent, .large], selection: $selectedDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: midDetent))
                    .interactiveDismissDisabled()
            }
        }
    }

    private var regularLayout: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                bottomSheetContent
                    .frame(width: 360)
                    .background(.regularMaterial)

                if showProfilePanel {
                    ProfileView(isPresented: $showProfilePanel, useSheetPresentation: false)
                        .environmentObject(stampStore)
                        .frame(width: 420)
                        .background(.regularMaterial)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: -2, y: 0)
                        .zIndex(1)
                        .transition(.move(edge: .trailing))
                }
            }
            .frame(width: showProfilePanel ? 420 : 360)
            .animation(.easeInOut(duration: 0.25), value: showProfilePanel)

            ZStack {
                mapView
                floatingToolbar
            }
        }
    }

    @ViewBuilder
    private var mapView: some View {
        if useOfflineMap {
            OfflineMapView(
                initialCenter: initialCenter,
                cameraPosition: $cameraPosition,
                mapCameraCenter: $mapCameraCenter,
                filteredBikePoints: filteredBikePoints,
                selectedBikePoint: $selectedBikePoint,
                destinationCoordinate: destinationCoordinate,
                isCompact: isCompact,
                onBikePointTap: { bikePoint in
                    withAnimation(.spring(response: 0.3)) {
                        selectedBikePoint = bikePoint
                        sheetMode = .bikePointDetail
                        if isCompact {
                            selectedDetent = midDetent
                        }
                        cameraPosition = .region(MKCoordinateRegion(
                            center: CLLocationCoordinate2D(
                                latitude: bikePoint.coordinate.latitude - (isCompact ? 0.001 : 0),
                                longitude: bikePoint.coordinate.longitude
                            ),
                            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                        ))
                    }
                },
                onMapTap: {
                    if selectedBikePoint != nil {
                        withAnimation {
                            selectedBikePoint = nil
                            sheetMode = .search
                            if isCompact {
                                selectedDetent = collapsedDetent
                            }
                        }
                    }
                }
            )
            .onChange(of: locationManager.userLocation) { _, newLocation in
                guard !hasMovedCamera, let newLocation else { return }
                let userLoc = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
                let cityLoc = CLLocation(latitude: initialCenter.latitude, longitude: initialCenter.longitude)
                if userLoc.distance(from: cityLoc) < 50_000 {
                    hasMovedCamera = true
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: newLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }
            }
        } else {
            Map(position: $cameraPosition) {
                UserAnnotation()

                ForEach(filteredBikePoints) { bikePoint in
                    Annotation(bikePoint.commonName, coordinate: bikePoint.coordinate, anchor: .bottom) {
                        BikePointMarker(
                            bikePoint: bikePoint,
                            isSelected: selectedBikePoint?.id == bikePoint.id
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                selectedBikePoint = bikePoint
                                sheetMode = .bikePointDetail
                                if isCompact {
                                    selectedDetent = midDetent
                                }
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(
                                        latitude: bikePoint.coordinate.latitude - (isCompact ? 0.001 : 0),
                                        longitude: bikePoint.coordinate.longitude
                                    ),
                                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                ))
                            }
                        }
                    }
                }

                // Destination pin when search result is selected
                if let dest = destinationCoordinate {
                    Marker("Destination", coordinate: dest)
                        .tint(.orange)
                }
            }
            .mapStyle(.standard(pointsOfInterest: .excludingAll))
            .safeAreaPadding(.bottom, isCompact ? 100 : 0)
            .mapControls {
                MapScaleView()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                mapCameraCenter = context.region.center
            }
            .onTapGesture { _ in
                if selectedBikePoint != nil {
                    withAnimation {
                        selectedBikePoint = nil
                        sheetMode = .search
                        if isCompact {
                            selectedDetent = collapsedDetent
                        }
                    }
                }
            }
            .onChange(of: locationManager.userLocation) { _, newLocation in
                guard !hasMovedCamera, let newLocation else { return }
                let userLoc = CLLocation(latitude: newLocation.latitude, longitude: newLocation.longitude)
                let cityLoc = CLLocation(latitude: initialCenter.latitude, longitude: initialCenter.longitude)
                if userLoc.distance(from: cityLoc) < 50_000 {
                    hasMovedCamera = true
                    withAnimation {
                        cameraPosition = .region(MKCoordinateRegion(
                            center: newLocation,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        ))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var floatingToolbar: some View {
        VStack {
            // City-switch suggestion banner — drawn inline in the map area so it
            // doesn't conflict with the permanent bottom-sheet presentation.
            if showCitySwitchAlert, let cityName = suggestedCityName, let systemName = suggestedSystemName {
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("You're near \(cityName)")
                            .font(.subheadline.weight(.semibold))
                        Text("Switch to \(systemName)?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Switch") {
                        if let id = suggestedProviderID { storedProviderID = id }
                        withAnimation { showCitySwitchAlert = false }
                    }
                    .font(.subheadline.weight(.semibold))
                    .buttonStyle(.borderless)
                    Button {
                        withAnimation { showCitySwitchAlert = false }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
                .padding(.top, 16)
                .padding(.horizontal, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            HStack {
                Spacer()
                VStack(spacing: 0) {
                    Button {
                        Task { await bikePointService.fetchBikePoints() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: toolbarIconSize, weight: .medium))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(NSLocalizedString("a11y_refresh_stations", bundle: .localized, comment: ""))

                    Divider()
                        .frame(width: 30)

                    Button {
                        withAnimation {
                            if let location = locationManager.userLocation {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: location,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ))
                            } else {
                                // Location not available — show selected city centre
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: initialCenter,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                ))
                            }
                        }
                    } label: {
                        Image(systemName: locationManager.userLocation != nil ? "location.fill" : "location.slash.fill")
                            .font(.system(size: toolbarIconSize, weight: .medium))
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel(NSLocalizedString("a11y_centre_on_location", bundle: .localized, comment: ""))
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
            }
            .padding(.top, 16)
            .padding(.trailing, 12)

            HStack(alignment: .center, spacing: 8) {
                Spacer()

                if showDebugTooltip {
                    HStack(spacing: 6) {
                        Text("Try out demo features!")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                        Image(systemName: "arrow.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .offset(x: 8)),
                        removal: .opacity.combined(with: .offset(x: 8))
                    ))
                    .onTapGesture {
                        if reduceMotion { showDebugTooltip = false }
                        else { withAnimation(.spring(duration: 0.3)) { showDebugTooltip = false } }
                        hasSeenDebugTooltip = true
                    }
                }

                Button {
                    if reduceMotion { showDebugTooltip = false }
                    else { withAnimation(.spring(duration: 0.3)) { showDebugTooltip = false } }
                    hasSeenDebugTooltip = true
                    showDebugMenu = true
                } label: {
                    Image(systemName: "ladybug")
                        .font(.system(size: toolbarIconSize, weight: .medium))
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(NSLocalizedString("a11y_debug_menu", bundle: .localized, comment: ""))
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .sheet(isPresented: $showDebugMenu) {
                    NavigationStack {
                        DebugMenuView(retriggerCitySuggestion: {
                            // Reset suggestion state so the next location update re-runs the check.
                            hasSuggestedCitySwitch = false
                            showCitySwitchAlert = false
                            suggestedProviderID = nil
                            suggestedCityName = nil
                            suggestedSystemName = nil
                        })
                        .environmentObject(searchHistoryStore)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackground(.regularMaterial)
                }
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
            .onAppear {
                if !hasSeenDebugTooltip {
                    if reduceMotion { showDebugTooltip = true }
                    else { withAnimation(.spring(duration: 0.4).delay(0.8)) { showDebugTooltip = true } }
                }
            }

            Spacer()
        }
        .animation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.85), value: showCitySwitchAlert)
    }

    private func updateNearbyStamps(location: CLLocationCoordinate2D?) {
        guard let location else {
            withAnimation { nearbyStamps = [] }
            return
        }
        let coord = Coordinate(latitude: location.latitude, longitude: location.longitude)
        withAnimation { nearbyStamps = stampStore.nearbyUnclaimed(at: coord) }
    }

    /// Once per session: if the user's GPS fix is far from the selected city
    /// but close to another supported city, surface a banner to switch.
    /// Called on every location update until the check succeeds — hasSuggestedCitySwitch
    /// is only set to true once providers are confirmed registered, so a simulator's
    /// immediate first-fix before OnboardingHost's .task runs can't silence the check.
    private func checkCitySuggestion(for location: CLLocationCoordinate2D?) {
        guard !hasSuggestedCitySwitch, let location else { return }

        let userLoc = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let cityLoc = CLLocation(latitude: initialCenter.latitude, longitude: initialCenter.longitude)

        // Already close to the selected city — lock out further checks and return.
        if userLoc.distance(from: cityLoc) <= 30_000 {
            hasSuggestedCitySwitch = true
            return
        }

        // Providers may not be registered yet (race with OnboardingHost .task on
        // fast devices/simulators). If the list is empty, skip this update and let
        // the next location event retry — don't set hasSuggestedCitySwitch yet.
        let providers = ProviderRegistry.shared.providers
            .compactMap { $0 as? any OnboardingCityProvider }
            .filter { $0.id != (selectedProviderID ?? "") }

        guard !providers.isEmpty else { return }

        // Providers are ready — this is our one check for the session.
        hasSuggestedCitySwitch = true

        var bestProvider: (any OnboardingCityProvider)? = nil
        var bestDistance: CLLocationDistance = 50_000

        for provider in providers {
            let loc = CLLocation(
                latitude: provider.defaultCenter.latitude,
                longitude: provider.defaultCenter.longitude
            )
            let dist = userLoc.distance(from: loc)
            if dist < bestDistance {
                bestDistance = dist
                bestProvider = provider
            }
        }

        guard let provider = bestProvider else { return }
        suggestedProviderID = provider.id
        suggestedCityName = provider.cityDisplayName
        suggestedSystemName = provider.systemDisplayName
        showCitySwitchAlert = true
    }
}
