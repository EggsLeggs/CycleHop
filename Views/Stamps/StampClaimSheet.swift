import SwiftUI

/// Sheet to view and claim nearby stamps (paged, with motion and claim button).
struct StampClaimSheet: View {
    let stamps: [StampDefinition]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var stampStore: StampStore
    @StateObject private var motionManager = MotionManager()
    @State private var currentPage = 0

    private var currentStamp: StampDefinition? {
        guard stamps.indices.contains(currentPage) else { return nil }
        return stamps[currentPage]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Close
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(NSLocalizedString("a11y_close", bundle: .localized, comment: ""))
                .padding(.trailing, 20)
                .padding(.top, 20)
            }

            TabView(selection: $currentPage) {
                ForEach(Array(stamps.enumerated()), id: \.element.id) { index, stamp in
                    stampPage(for: stamp)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: stamps.count > 1 ? .automatic : .never))

            // Action buttons
            VStack(spacing: 8) {
                if stamps.count > 1 {
                    Button {
                        stampStore.claimAll(stamps)
                        dismiss()
                    } label: {
                        Text("Add All")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        if let stamp = currentStamp {
                            stampStore.claimStamp(id: stamp.id)
                        }
                        dismiss()
                    } label: {
                        Text("Add stamp")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        if let stamp = currentStamp {
                            stampStore.claimStamp(id: stamp.id)
                        }
                        dismiss()
                    } label: {
                        Text("Add stamp")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .presentationDetents([stamps.count > 1 ? PresentationDetent.fraction(0.65) : PresentationDetent.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            if !reduceMotion { motionManager.start() }
            let allClaimed = stamps.allSatisfy { stampStore.isAlreadyClaimed($0) }
            if allClaimed { dismiss() }
        }
        .onDisappear {
            motionManager.stop()
        }
    }

    @ViewBuilder
    private func stampPage(for stamp: StampDefinition) -> some View {
        VStack(spacing: 16) {
            Spacer()

            StampImageView(stampPNGBaseName: stamp.stampPNGBaseName, size: 200, isDecorative: true)
                .rotation3DEffect(
                    Angle(radians: reduceMotion ? 0 : motionManager.roll * 0.3),
                    axis: (x: 0, y: 1, z: 0)
                )
                .rotation3DEffect(
                    Angle(radians: reduceMotion ? 0 : -motionManager.pitch * 0.2),
                    axis: (x: 1, y: 0, z: 0)
                )
                .shadow(
                    color: .black.opacity(0.2),
                    radius: 12,
                    x: reduceMotion ? 0 : CGFloat(motionManager.roll * 8),
                    y: reduceMotion ? 4 : CGFloat(motionManager.pitch * 8) + 4
                )

            VStack(spacing: 4) {
                Text(LocalizedStringKey(stamp.displayName))
                    .font(.title2)
                    .fontWeight(.bold)

                Text(Date(), style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}
