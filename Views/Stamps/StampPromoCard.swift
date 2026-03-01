import SwiftUI

/// Promo card for a nearby stamp with image, name, date, tap to claim, dismiss button.
struct StampPromoCard: View {
    let stamp: StampDefinition
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        ZStack(alignment: .trailing) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    StampImageView(stampPNGBaseName: stamp.stampPNGBaseName, size: 48, isDecorative: true)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stamp Available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(LocalizedStringKey(stamp.displayName))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(Date(), style: .date)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
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
