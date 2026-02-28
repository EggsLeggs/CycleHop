import SwiftUI

struct StampPromoCard: View {
    let stamp: StampDefinition
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            StampImageView(stampPNGBaseName: stamp.stampPNGBaseName, size: 48)

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

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
    }
}
