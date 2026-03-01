import SwiftUI

/// Debug menu: tooltips, profile reset, onboarding reset, stamp injection, location.
struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stampStore: StampStore
    @EnvironmentObject private var searchHistoryStore: SearchHistoryStore
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasSeenDebugTooltip") private var hasSeenDebugTooltip = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    /// Called when the user taps "Retrigger city suggestion". Provided by ContentView.
    var retriggerCitySuggestion: (() -> Void)? = nil

    @State private var selectedStampID = ""

    private let iconWidth: CGFloat = 24
    private let rowSpacing: CGFloat = 12
    private var dividerInset: CGFloat { 16 + iconWidth + rowSpacing }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Location

                Text("Location")
                    .font(.title3.bold())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                Divider()

                Button {
                    retriggerCitySuggestion?()
                    dismiss()
                } label: {
                    debugRow(icon: "mappin.circle", title: "Retrigger city suggestion banner")
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, dividerInset)

                NavigationLink {
                    ChangeLocationView()
                        .environmentObject(ProviderRegistry.shared)
                } label: {
                    debugRow(icon: "mappin.and.ellipse", title: "Change Location")
                }
                .buttonStyle(.plain)

                Divider()

                // Onboarding

                Text("Onboarding")
                    .font(.title3.bold())
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 8)

                Divider()

                Button {
                    hasCompletedOnboarding = false
                } label: {
                    debugRow(icon: "arrow.uturn.backward", title: "Restart onboarding", tint: .red)
                }
                .buttonStyle(.plain)

                Divider()

                // Tooltips

                Text("Tooltips")
                    .font(.title3.bold())
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 8)

                Divider()

                Button {
                    hasSeenDebugTooltip = false
                } label: {
                    debugRow(icon: "arrow.counterclockwise", title: "Retrigger demo button tooltip")
                }
                .buttonStyle(.plain)

                Divider()

                // Profile

                Text("Profile")
                    .font(.title3.bold())
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 8)

                Divider()

                Button {
                    userName = ""
                } label: {
                    debugRow(icon: "person.crop.circle.badge.minus", title: "Reset name", tint: .red)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, dividerInset)

                Button {
                    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        .appendingPathComponent("profile_image.jpg")
                    try? FileManager.default.removeItem(at: url)
                } label: {
                    debugRow(icon: "person.crop.circle.badge.minus", title: "Remove profile photo", tint: .red)
                }
                .buttonStyle(.plain)

                Divider()

                // Stamps

                Text("Stamps")
                    .font(.title3.bold())
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 8)

                Divider()

                Button {
                    stampStore.resetAllStamps()
                } label: {
                    debugRow(icon: "seal.fill", title: "Reset Stamps", tint: .red)
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, dividerInset)

                Button {
                    stampStore.claimAll(stampStore.allDefinitions)
                } label: {
                    debugRow(icon: "seal.fill", title: "Add all stamps")
                }
                .buttonStyle(.plain)

                if !stampStore.allDefinitions.isEmpty {
                    Divider().padding(.leading, dividerInset)

                    HStack(spacing: rowSpacing) {
                        Image(systemName: "plus.circle")
                            .frame(width: iconWidth)
                        Text("Add Stamp")
                        Spacer()
                        Picker("Add Stamp", selection: $selectedStampID) {
                            Text("Select…").tag("")
                            ForEach(stampStore.allDefinitions) { definition in
                                Text(LocalizedStringKey(definition.displayName)).tag(definition.id)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .onChange(of: selectedStampID) { _, newValue in
                            guard !newValue.isEmpty else { return }
                            stampStore.claimStamp(id: newValue)
                            selectedStampID = ""
                        }
                    }
                    .frame(minHeight: 54)
                    .padding(.horizontal, 16)
                }

                Divider()

                // Search

                Text("Search")
                    .font(.title3.bold())
                    .padding(.horizontal, 16)
                    .padding(.top, 28)
                    .padding(.bottom, 8)

                Divider()

                Button {
                    searchHistoryStore.reset()
                } label: {
                    debugRow(icon: "clock.arrow.circlepath", title: "Reset search history", tint: .red)
                }
                .buttonStyle(.plain)

                Divider()
            }
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Debug")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    private func debugRow(icon: String, title: LocalizedStringKey, tint: Color? = nil) -> some View {
        HStack(spacing: rowSpacing) {
            Image(systemName: icon)
                .foregroundStyle(tint ?? .primary)
                .frame(width: iconWidth)
            Text(title)
            Spacer()
        }
        .frame(minHeight: 54)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}
