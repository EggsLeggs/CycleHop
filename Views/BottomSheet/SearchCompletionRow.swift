import SwiftUI
import MapKit

struct SearchCompletionRow: View {
    let completion: MKLocalSearchCompletion

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)

            VStack(alignment: .leading, spacing: 2) {
                Text(completion.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if !completion.subtitle.isEmpty {
                    Text(completion.subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
