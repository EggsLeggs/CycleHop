import SwiftUI

/// Stamp-style promo card shown in the bottom sheet when live GPS detects the user near a different city.
struct LocationMismatchCard: View {
    let cityName: String
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.tint)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(NSLocalizedString("location_mismatch_title", bundle: .localized, comment: ""))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(String(format: NSLocalizedString("location_mismatch_body", bundle: .localized, comment: ""), cityName))
                            .font(.subheadline.weight(.semibold))
                        Text(NSLocalizedString("location_mismatch_action", bundle: .localized, comment: ""))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(format: NSLocalizedString("a11y_location_mismatch_format", bundle: .localized, comment: ""), cityName))
            .accessibilityHint(NSLocalizedString("a11y_location_mismatch_hint", bundle: .localized, comment: ""))
            .accessibilityAction(named: NSLocalizedString("a11y_dismiss", bundle: .localized, comment: "")) {
                onDismiss()
            }

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
            .accessibilityLabel(NSLocalizedString("a11y_dismiss", bundle: .localized, comment: ""))
            .buttonStyle(.plain)
            .padding(.trailing, 16)
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}
