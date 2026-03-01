import SwiftUI
import MapKit

/// Bottom sheet content: header plus search, search results, or bike point detail.
struct BottomSheetView: View {
    @Binding var sheetMode: SheetMode
    @Binding var searchText: String
    @Binding var selectedBikePoint: BikePoint?
    @Binding var destinationCoordinate: CLLocationCoordinate2D?
    @Binding var cameraPosition: MapCameraPosition
    @Binding var selectedDetent: PresentationDetent
    @Binding var showStampClaimSheet: Bool
    let nearbyStamps: [StampDefinition]
    let midDetent: PresentationDetent
    let collapsedDetent: PresentationDetent
    @ObservedObject var bikePointService: BikePointService
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var searchCompleter: SearchCompleter
    @ObservedObject var stampStore: StampStore

    @State private var destinationName: String?
    @State private var showProfilePanel = false

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
                        userLocation: locationManager.userLocation,
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
                        userLocation: locationManager.userLocation,
                        bikePointService: bikePointService
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxHeight: .infinity, alignment: .top)
        .sheet(isPresented: $showProfilePanel) {
            ProfileView(startingDetent: selectedDetent == .large ? .large : .medium)
        }
        .onChange(of: searchText) { _, newValue in
            searchCompleter.searchQuery = newValue
        }
        .onChange(of: sheetMode) { _, newValue in
            if newValue == .search {
                destinationCoordinate = nil
                destinationName = nil
            }
        }
    }

    @ViewBuilder
    private var searchContent: some View {
        if !searchText.isEmpty {
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
        } else {
            let promoStamps = nearbyStamps.filter { !stampStore.dismissedPromoIDs.contains($0.id) }
            if !promoStamps.isEmpty && selectedDetent != collapsedDetent {
                VStack(spacing: 0) {
                    ForEach(promoStamps) { stamp in
                        StampPromoCard(
                            stamp: stamp,
                            onTap: { showStampClaimSheet = true },
                            onDismiss: { stampStore.dismissPromo(id: stamp.id) }
                        )
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    private func selectCompletion(_ completion: MKLocalSearchCompletion) {
        Task {
            if let coordinate = await searchCompleter.search(for: completion) {
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
