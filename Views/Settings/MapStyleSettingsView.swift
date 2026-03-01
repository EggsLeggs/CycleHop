import SwiftUI

/// Settings screen for offline vs Apple Maps with explanation and toggle.
struct MapStyleSettingsView: View {
    @AppStorage("useOfflineMap") private var useOfflineMap = true
    @State private var previewImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Color(.secondarySystemBackground)
                    .frame(height: 220)
                    .overlay {
                        if let previewImage {
                            Image(uiImage: previewImage)
                                .resizable()
                                .scaledToFill()
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 12) {
                    Text("This app is built for the Swift Student Challenge, which requires projects to work fully offline. The bundled offline map uses OpenStreetMap tiles so everything works without a network connection. If you have Apple Maps regions downloaded for offline use, Apple Maps should work here too.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Picker("Map Style", selection: $useOfflineMap) {
                        Text("Offline Map").tag(true)
                        Text("Apple Maps").tag(false)
                    }
                    .pickerStyle(.segmented)

                    if useOfflineMap {
                        Label(
                            "Offline Map works without an internet connection using locally bundled tiles.",
                            systemImage: "wifi.slash"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    } else {
                        Label(
                            "Apple Maps shows live map data but requires an internet connection.",
                            systemImage: "wifi"
                        )
                        .font(.footnote)
                        .foregroundStyle(.orange)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Map Style")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadPreview() }
        .onChange(of: useOfflineMap) { loadPreview() }
    }

    private func loadPreview() {
        let name = useOfflineMap ? "OfflineMap" : "OnlineMap"
        previewImage = UIImage(named: name)
    }
}
