import SwiftUI
import MapKit

struct BottomSheetView: View {
    @Binding var sheetMode: SheetMode
    @Binding var searchText: String
    @Binding var selectedBikePoint: BikePoint?
    @Binding var destinationCoordinate: CLLocationCoordinate2D?
    @Binding var cameraPosition: MapCameraPosition
    @Binding var selectedDetent: PresentationDetent
    let midDetent: PresentationDetent
    @ObservedObject var bikePointService: BikePointService
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var searchCompleter: SearchCompleter

    @State private var destinationName: String?

    var body: some View {
        VStack(spacing: 0) {
            SheetHeader(
                sheetMode: $sheetMode,
                searchText: $searchText,
                selectedBikePoint: $selectedBikePoint,
                selectedDetent: $selectedDetent,
                midDetent: midDetent,
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
