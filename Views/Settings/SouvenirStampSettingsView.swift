import SwiftUI

/// Settings screen for souvenir stamps (show unowned toggle and description).
struct SouvenirStampSettingsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("showUnownedStamps") private var showUnownedStamps = false

    @State private var headerImage: UIImage?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    if let img = headerImage {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                    } else {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.08))
                            .aspectRatio(1.2, contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                Image(systemName: "seal.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(.quaternary)
                            }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.separator), lineWidth: 0.5)
                )

                Text("Souvenir stamps are collectible markers you earn by visiting real-world locations. Each city and attraction has its own unique stamp design. Explore new places to grow your collection.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Toggle(isOn: $showUnownedStamps) {
                    Label("Show Unowned Stamps", systemImage: "eye")
                }

                Text("When enabled, stamps you haven't collected yet will appear in your stamp book as greyed-out placeholders.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Souvenir Stamps")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { loadImage() }
        .onChange(of: colorScheme) { _, _ in loadImage() }
    }

    private func loadImage() {
        let name = colorScheme == .dark ? "StampSplashDark" : "StampSplash"
        headerImage = UIImage(named: name)
    }
}
