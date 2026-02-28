import SwiftUI

struct StampClaimSheet: View {
    let stamps: [StampDefinition]

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stampStore: StampStore
    @StateObject private var motionManager = MotionManager()
    @State private var currentPage = 0

    private var currentStamp: StampDefinition? {
        guard stamps.indices.contains(currentPage) else { return nil }
        return stamps[currentPage]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Close button
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            motionManager.start()
            // If all stamps already claimed, dismiss immediately
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

            StampImageView(stampPNGBaseName: stamp.stampPNGBaseName, size: 200)
                .rotation3DEffect(
                    Angle(radians: motionManager.roll * 0.3),
                    axis: (x: 0, y: 1, z: 0)
                )
                .rotation3DEffect(
                    Angle(radians: -motionManager.pitch * 0.2),
                    axis: (x: 1, y: 0, z: 0)
                )
                .shadow(
                    color: .black.opacity(0.2),
                    radius: 12,
                    x: CGFloat(motionManager.roll * 8),
                    y: CGFloat(motionManager.pitch * 8) + 4
                )

            VStack(spacing: 4) {
                Text(stamp.displayName)
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
