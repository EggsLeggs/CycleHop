import SwiftUI
import MapKit

struct ContentView: View {
    let selectedProviderID: String?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var bikePointService = BikePointService()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()

    @State private var selectedBikePoint: BikePoint? = nil
    @State private var sheetMode: SheetMode = .search
    @State private var searchText: String = ""
    @State private var destinationCoordinate: CLLocationCoordinate2D? = nil
    @State private var cameraPosition: MapCameraPosition
    @State private var mapCameraCenter: CLLocationCoordinate2D? = nil
    @State private var selectedDetent: PresentationDetent = .height(90)
    @State private var midDetentHeight: CGFloat = 384
    @State private var hasMovedCamera = false
    @AppStorage("hasSeenDebugTooltip") private var hasSeenDebugTooltip = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showDebugTooltip = false
    @State private var showDebugMenu = false

    private let initialCenter: CLLocationCoordinate2D

    init(selectedProviderID: String? = nil) {
        self.selectedProviderID = selectedProviderID

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
            midDetent: midDetent,
            bikePointService: bikePointService,
            locationManager: locationManager,
            searchCompleter: searchCompleter
        )
    }

    var body: some View {
        if isCompact {
            compactLayout
        } else {
            regularLayout
        }
    }

    private var compactLayout: some View {
        GeometryReader { geometry in
            ZStack {
                mapView
                floatingToolbar
            }
            .onAppear {
                midDetentHeight = min(350 + geometry.safeAreaInsets.bottom, geometry.size.height)
            }
            .sheet(isPresented: .constant(true)) {
                bottomSheetContent
                    .presentationDetents([.height(90), midDetent, .large], selection: $selectedDetent)
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled(upThrough: midDetent))
                    .interactiveDismissDisabled()
            }
        }
    }

    private var regularLayout: some View {
        HStack(spacing: 0) {
            bottomSheetContent
                .frame(width: 360)
                .background(.regularMaterial)

            ZStack {
                mapView
                floatingToolbar
            }
        }
    }

    @ViewBuilder
    private var mapView: some View {
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

            // Destination pin
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
                        selectedDetent = .height(90)
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

    @ViewBuilder
    private var floatingToolbar: some View {
        VStack {
            HStack {
                Spacer()
                VStack(spacing: 0) {
                    Button {
                        Task { await bikePointService.fetchBikePoints() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 44, height: 44)
                    }

                    Divider()
                        .frame(width: 30)

                    Button {
                        if let location = locationManager.userLocation {
                            withAnimation {
                                cameraPosition = .region(MKCoordinateRegion(
                                    center: location,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ))
                            }
                        }
                    } label: {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 44, height: 44)
                    }
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
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.primary)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
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
                        withAnimation(.spring(duration: 0.3)) {
                            showDebugTooltip = false
                        }
                        hasSeenDebugTooltip = true
                    }
                }

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        showDebugTooltip = false
                    }
                    hasSeenDebugTooltip = true
                    showDebugMenu = true
                } label: {
                    Image(systemName: "ladybug")
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 44, height: 44)
                }
                .background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                .sheet(isPresented: $showDebugMenu) {
                    DebugMenuView(
                        onRetriggerTooltip: {
                            hasSeenDebugTooltip = false
                            showDebugMenu = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                withAnimation(.spring(duration: 0.4)) {
                                    showDebugTooltip = true
                                }
                            }
                        },
                        onRestartOnboarding: {
                            hasCompletedOnboarding = false
                        }
                    )
                }
            }
            .padding(.top, 8)
            .padding(.trailing, 12)
            .onAppear {
                if !hasSeenDebugTooltip {
                    withAnimation(.spring(duration: 0.4).delay(0.8)) {
                        showDebugTooltip = true
                    }
                }
            }

            Spacer()
        }
    }
}
