import SwiftUI
import MapKit

struct SheetHeader: View {
    @Binding var sheetMode: SheetMode
    @Binding var searchText: String
    @Binding var selectedBikePoint: BikePoint?
    @Binding var selectedDetent: PresentationDetent
    @Binding var showProfilePanel: Bool
    let midDetent: PresentationDetent
    let collapsedDetent: PresentationDetent
    let destinationName: String?
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            switch sheetMode {
            case .search:
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search for a destination", text: $searchText)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                        .focused($isSearchFocused)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(NSLocalizedString("a11y_clear_search", bundle: .localized, comment: ""))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))

                Button {
                    showProfilePanel = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(NSLocalizedString("a11y_profile", bundle: .localized, comment: ""))

            case .searchResults:
                Button {
                    sheetMode = .search
                    selectedDetent = collapsedDetent
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel(NSLocalizedString("a11y_back", bundle: .localized, comment: ""))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Stations near")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(LocalizedStringKey(destinationName ?? NSLocalizedString("Location", bundle: .localized, comment: "")))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                Spacer()

            case .bikePointDetail:
                Button {
                    if destinationName != nil {
                        sheetMode = .searchResults
                        selectedDetent = midDetent
                    } else {
                        sheetMode = .search
                        selectedDetent = collapsedDetent
                    }
                    selectedBikePoint = nil
                } label: {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                }
                .accessibilityLabel(NSLocalizedString("a11y_back", bundle: .localized, comment: ""))

                if let bikePoint = selectedBikePoint {
                    let parts = bikePoint.commonName.splitBikePointName()
                    VStack(alignment: .leading, spacing: 1) {
                        Text(parts.primary)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        if let secondary = parts.secondary {
                            Text(secondary)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Spacer()

                if let bikePoint = selectedBikePoint {
                    Button {
                        openInMaps(bikePoint)
                    } label: {
                        Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel(NSLocalizedString("a11y_get_directions", bundle: .localized, comment: ""))
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .onChange(of: isSearchFocused) { _, focused in
            if focused {
                withAnimation {
                    selectedDetent = .large
                }
            }
        }
    }

    private func openInMaps(_ bikePoint: BikePoint) {
        let placemark = MKPlacemark(coordinate: bikePoint.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = bikePoint.commonName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ])
    }
}
