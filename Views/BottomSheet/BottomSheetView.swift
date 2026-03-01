import SwiftUI
import MapKit

/// Presents the profile as a sheet only when isCompact (iPhone). On iPad the profile is shown in the layout, not from here.
private struct ProfileSheetOnCompactModifier: ViewModifier {
    let isCompact: Bool
    @Binding var showProfilePanel: Bool
    let selectedDetent: PresentationDetent
    @ObservedObject var stampStore: StampStore

    func body(content: Content) -> some View {
        if isCompact {
            content
                .sheet(isPresented: $showProfilePanel, onDismiss: { showProfilePanel = false }) {
                    ProfileView(isPresented: $showProfilePanel, useSheetPresentation: true, startingDetent: selectedDetent == .large ? .large : .medium)
                        .environmentObject(stampStore)
                }
        } else {
            content
        }
    }
}

/// Bottom sheet content: header plus search, search results, or bike point detail.
struct BottomSheetView: View {
    @Binding var sheetMode: SheetMode
    @Binding var searchText: String
    @Binding var selectedBikePoint: BikePoint?
    @Binding var destinationCoordinate: CLLocationCoordinate2D?
    @Binding var cameraPosition: MapCameraPosition
    @Binding var selectedDetent: PresentationDetent
    @Binding var showStampClaimSheet: Bool
    @Binding var showProfilePanel: Bool
    @Binding var showCitySwitchAlert: Bool
    var isCompact: Bool
    let nearbyStamps: [StampDefinition]
    let midDetent: PresentationDetent
    let collapsedDetent: PresentationDetent
    let effectiveUserLocation: CLLocationCoordinate2D?
    let suggestedCityName: String?
    let onSwitchCity: () -> Void
    let onDismissMismatch: () -> Void
    @ObservedObject var bikePointService: BikePointService
    @ObservedObject var searchCompleter: SearchCompleter
    @ObservedObject var stampStore: StampStore
    @ObservedObject var searchHistoryStore: SearchHistoryStore
    @ObservedObject var networkMonitor: NetworkMonitor

    @AppStorage("mockLocationMode") private var mockLocationMode = "landmark"
    @AppStorage("mockLandmarkID") private var mockLandmarkID = ""
    @AppStorage("selectedProviderID") private var selectedProviderID = ""
    @AppStorage("hasSeenMockLocationExplainer") private var hasSeenMockLocationExplainer = false

    @Binding var showMockLocationExplainer: Bool

    @State private var destinationName: String?

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(
                sheetMode: $sheetMode,
                searchText: $searchText,
                selectedBikePoint: $selectedBikePoint,
                selectedDetent: $selectedDetent,
                showProfilePanel: $showProfilePanel,
                midDetent: midDetent,
                collapsedDetent: collapsedDetent,
                destinationName: destinationName
            )

            switch sheetMode {
            case .search:
                searchContent

            case .searchResults:
                if let destinationCoordinate {
                    SearchResultsContent(
                        destinationCoordinate: destinationCoordinate,
                        bikePoints: bikePointService.bikePoints,
                        userLocation: effectiveUserLocation,
                        selectedBikePoint: $selectedBikePoint,
                        sheetMode: $sheetMode,
                        cameraPosition: $cameraPosition,
                        selectedDetent: $selectedDetent,
                        midDetent: midDetent
                    )
                }

            case .bikePointDetail:
                if let bikePoint = selectedBikePoint {
                    BikePointDetailContent(
                        bikePoint: bikePoint,
                        userLocation: effectiveUserLocation,
                        bikePointService: bikePointService
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .onChange(of: searchText) { _, newValue in
            searchCompleter.searchQuery = newValue
        }
        .onChange(of: sheetMode) { _, newValue in
            if newValue == .search {
                destinationCoordinate = nil
                destinationName = nil
            }
        }
        .modifier(ProfileSheetOnCompactModifier(
            isCompact: isCompact,
            showProfilePanel: $showProfilePanel,
            selectedDetent: selectedDetent,
            stampStore: stampStore
        ))
        .sheet(isPresented: $showMockLocationExplainer, onDismiss: { hasSeenMockLocationExplainer = true }) {
            MockLocationExplainerSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        let hasSearchQuery = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasSearchQuery {
            if networkMonitor.isOffline {
                SearchNotFoundView(
                    headlineKey: "search_offline_headline",
                    bodyKey: "search_offline_body"
                )
            } else if searchCompleter.completions.isEmpty {
                SearchNotFoundView(
                    headlineKey: "search_no_results_headline",
                    bodyKey: "search_no_results_body"
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchCompleter.completions, id: \.self) { completion in
                            Button {
                                selectCompletion(completion)
                            } label: {
                                SearchCompletionRow(completion: completion)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 52)
                        }
                    }
                }
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if mockLocationMode == "landmark" && selectedDetent != collapsedDetent {
                        let landmarks = (ProviderRegistry.shared.provider(id: selectedProviderID) as? any OnboardingCityProvider)?.landmarks ?? []
                        if landmarks.count > 1 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(landmarks) { landmark in
                                        Button {
                                            mockLandmarkID = landmark.id
                                        } label: {
                                            Text(landmark.displayName)
                                                .font(.caption.weight(.medium))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(mockLandmarkID == landmark.id ? Color.accentColor : Color(.tertiarySystemBackground))
                                                .foregroundStyle(mockLandmarkID == landmark.id ? Color.white : Color.primary)
                                                .clipShape(Capsule())
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityAddTraits(mockLandmarkID == landmark.id ? .isSelected : [])
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                            }
                        }
                    }

                    if showCitySwitchAlert, let cityName = suggestedCityName, selectedDetent != collapsedDetent {
                        LocationMismatchCard(
                            cityName: cityName,
                            onTap: onSwitchCity,
                            onDismiss: onDismissMismatch
                        )
                        .padding(.top, 4)
                    }

                    let promoStamps = nearbyStamps.filter { !stampStore.dismissedPromoIDs.contains($0.id) }
                    if !promoStamps.isEmpty && selectedDetent != collapsedDetent {
                        ForEach(promoStamps) { stamp in
                            StampPromoCard(
                                stamp: stamp,
                                onTap: { showStampClaimSheet = true },
                                onDismiss: { stampStore.dismissPromo(id: stamp.id) }
                            )
                        }
                        .padding(.top, 4)
                    }

                    if selectedDetent != collapsedDetent {
                        if searchHistoryStore.recentSearches.isEmpty {
                            SearchEmptyStateView()
                        } else {
                            Text(NSLocalizedString("Search history", bundle: .localized, comment: "Search history section title"))
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, promoStamps.isEmpty ? 4 : 16)
                                .padding(.bottom, 8)
                                .accessibilityAddTraits(.isHeader)
                                .accessibilityLabel(String(format: NSLocalizedString("a11y_search_history_section_format", bundle: .localized, comment: ""), searchHistoryStore.recentSearches.count))

                            ForEach(searchHistoryStore.recentSearches) { item in
                                Button {
                                    selectHistoryItem(item)
                                } label: {
                                    SearchHistoryRow(title: item.title, subtitle: item.subtitle)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(String(format: NSLocalizedString("a11y_search_history_item_format", bundle: .localized, comment: ""), item.title, item.subtitle))
                                .accessibilityHint(NSLocalizedString("a11y_search_history_hint", bundle: .localized, comment: ""))
                                Divider().padding(.leading, 52)
                            }
                        }
                    }
                }
            }
        }
    }

    private func selectHistoryItem(_ item: SearchHistoryItem) {
        destinationCoordinate = item.coordinate
        destinationName = item.title
        sheetMode = .searchResults
        searchText = ""
        cameraPosition = .region(MKCoordinateRegion(
            center: item.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
        ))
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        Task {
            if let coordinate = await searchCompleter.search(for: completion) {
                searchHistoryStore.add(
                    title: completion.title,
                    subtitle: completion.subtitle,
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
                destinationCoordinate = coordinate
                destinationName = completion.title
                sheetMode = .searchResults
                searchText = ""
                cameraPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                ))
            }
        }
    }
}
