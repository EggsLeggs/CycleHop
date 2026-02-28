import SwiftUI

struct StampPill: View {
    let nearbyStamps: [StampDefinition]
    let onTap: () -> Void

    private var label: String {
        nearbyStamps.count == 1 ? "New Stamp Available" : "\(nearbyStamps.count) Stamps Available"
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "seal.fill")
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
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
