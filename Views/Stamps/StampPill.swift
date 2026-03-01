import SwiftUI

/// Floating pill showing "New Stamp Available" or "N stamps available"; tap opens claim sheet.
struct StampPill: View {
    let nearbyStamps: [StampDefinition]
    let onTap: () -> Void

    private var label: String {
        nearbyStamps.count == 1
            ? NSLocalizedString("New Stamp Available", bundle: .localized, comment: "")
            : String(format: NSLocalizedString("stamps_available_format", bundle: .localized, comment: ""), nearbyStamps.count)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "seal.fill")
                    .font(.subheadline.weight(.semibold))
                Text(label)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }
}
