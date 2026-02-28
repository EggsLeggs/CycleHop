import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var registry: ProviderRegistry

    private let iconWidth: CGFloat = 24
    private let rowSpacing: CGFloat = 12
    private var dividerInset: CGFloat { 16 + iconWidth + rowSpacing }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink {
                        ChangeLocationView()
                            .environmentObject(registry)
                    } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 30))
                                .foregroundStyle(.secondary)
                                .frame(width: 44, height: 44)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Change Location")
                                    .font(.headline)
                                Text("Changes city theming and map centre")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .frame(minHeight: 54)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)

                    // --- Manage ---

                    Text("Manage")
                        .font(.title3.bold())
                        .padding(.horizontal, 16)
                        .padding(.top, 28)
                        .padding(.bottom, 8)

                    Divider()

                    NavigationLink {
                        DebugMenuView()
                    } label: {
                        settingsRow(icon: "ladybug", title: "Debug Menu")
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, dividerInset)

                    NavigationLink {
                        MapStyleSettingsView()
                    } label: {
                        settingsRow(icon: "map", title: "Online / Offline Maps")
                    }
                    .buttonStyle(.plain)

                    Divider()

                    // --- Customise ---

                    Text("Customise")
                        .font(.title3.bold())
                        .padding(.horizontal, 16)
                        .padding(.top, 28)
                        .padding(.bottom, 8)

                    Divider()

                    NavigationLink {
                        SouvenirStampSettingsView()
                    } label: {
                        settingsRow(icon: "seal", title: "Souvenir Stamps")
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, dividerInset)

                    NavigationLink {
                        LocaleSettingsView()
                    } label: {
                        settingsRow(icon: "globe", title: "Locales")
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.leading, dividerInset)

                    NavigationLink {
                        UnitsSettingsView()
                    } label: {
                        settingsRow(icon: "ruler", title: "Units")
                    }
                    .buttonStyle(.plain)

                    Divider()
                }
                .padding(.bottom, 32)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }

    private func settingsRow(icon: String, title: LocalizedStringKey) -> some View {
        HStack(spacing: rowSpacing) {
            Image(systemName: icon)
                .frame(width: iconWidth)
            Text(title)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .font(.system(size: 13, weight: .semibold))
        }
        .frame(minHeight: 54)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}
