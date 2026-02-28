import SwiftUI

struct MapStyleScreen: View {
    let providerID: String
    let onComplete: (String) -> Void

    @AppStorage("useOfflineMap") private var useOfflineMap = true
    @State private var showOnlineWarning = false
    @State private var previewImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Map preview image
                Color(.secondarySystemBackground)
                    .frame(height: 200)
                    .overlay {
                        if let previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.25), value: useOfflineMap)

                // Style cards
                HStack(spacing: 16) {
                    MapStyleCard(
                        icon: "map",
                        title: "Offline Map",
                        subtitle: "Works without internet",
                        isSelected: useOfflineMap,
                        accentColor: .green
                    ) {
                        useOfflineMap = true
                    }

                    MapStyleCard(
                        icon: "map.fill",
                        title: "Apple Maps",
                        subtitle: "Requires connection",
                        isSelected: !useOfflineMap,
                        accentColor: .blue
                    ) {
                        showOnlineWarning = true
                    }
                }
                .padding(.horizontal)

                // Bottom description with wifi icon
                Label {
                    Text(
                        useOfflineMap
                            ? "This app is built for the Swift Student Challenge, which requires offline support. The bundled map uses OpenStreetMap tiles and works anywhere - no connection needed."
                            : "Apple Maps loads live map tiles from Apple's servers. If you have offline regions downloaded in the Maps app, those will work here too."
                    )
                } icon: {
                    Image(systemName: useOfflineMap ? "wifi.slash" : "wifi")
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .animation(.default, value: useOfflineMap)
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Choose Your Map")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                OnboardingContinueButton("Continue") {
                    onComplete(providerID)
                }
                .padding(.vertical, 12)
            }
            .background(.regularMaterial)
        }
        .onAppear { loadPreview() }
        .onChange(of: useOfflineMap) { loadPreview() }
        .alert("Requires Internet", isPresented: $showOnlineWarning) {
            Button("Use Apple Maps Anyway", role: .destructive) {
                useOfflineMap = false
            }
            Button("Keep Offline Map", role: .cancel) {}
        } message: {
            Text("Apple Maps needs an internet connection to load map tiles. The offline map works anywhere.")
        }
    }

    private func loadPreview() {
        let name = useOfflineMap ? "OfflineMap" : "OnlineMap"
        previewImage = UIImage(named: name)
    }
}

// MARK: - Card component

private struct MapStyleCard: View {
    let icon: String
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(isSelected ? accentColor : .secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(accentColor)
                            .font(.system(size: 20))
                    }
                }

                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? accentColor : Color(.separator),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
