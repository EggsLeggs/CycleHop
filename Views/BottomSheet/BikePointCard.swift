import SwiftUI
import CoreLocation

/// Compact card: mini chart, name, bike/dock counts, optional badge and distance.
struct BikePointCard: View {
    let bikePoint: BikePoint
    let userLocation: CLLocationCoordinate2D?
    var badge: (text: String, color: Color)? = nil

    private var nameParts: (primary: String, secondary: String?) {
        bikePoint.commonName.splitBikePointName()
    }

    private var distanceText: String? {
        guard let userLocation else { return nil }
        let from = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let to = CLLocation(latitude: bikePoint.lat, longitude: bikePoint.lon)
        return formatDistance(from.distance(from: to))
    }

    var body: some View {
        HStack(spacing: 12) {
            BikePointMiniChart(
                standardBikes: bikePoint.nbStandardBikes ?? 0,
                eBikes: bikePoint.nbEBikes ?? 0,
                emptyDocks: bikePoint.nbEmptyDocks ?? 0,
                size: 40
            )

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(nameParts.primary)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    if let badge {
                        Text(LocalizedStringKey(badge.text))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badge.color.opacity(0.15))
                            .foregroundStyle(badge.color)
                            .clipShape(Capsule())
                    }
                }

                if let secondary = nameParts.secondary {
                    Text(secondary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                HStack(spacing: 12) {
                    Label("\(bikePoint.nbStandardBikes ?? 0)", systemImage: "bicycle")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .accessibilityLabel(String(format: NSLocalizedString("a11y_standard_bikes_format", bundle: .localized, comment: ""), bikePoint.nbStandardBikes ?? 0))

                    Label("\(bikePoint.nbEBikes ?? 0)", systemImage: "bolt.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .accessibilityLabel(String(format: NSLocalizedString("a11y_ebikes_format", bundle: .localized, comment: ""), bikePoint.nbEBikes ?? 0))

                    Label("\(bikePoint.nbEmptyDocks ?? 0)", systemImage: "square.dashed")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .accessibilityLabel(String(format: NSLocalizedString("a11y_empty_docks_format", bundle: .localized, comment: ""), bikePoint.nbEmptyDocks ?? 0))

                    if let distanceText {
                        Spacer()
                        Text(distanceText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
