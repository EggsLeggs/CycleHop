import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stampStore: StampStore
    @AppStorage("userName") private var userName = ""
    @AppStorage("hasSeenDebugTooltip") private var hasSeenDebugTooltip = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @State private var selectedStampID = ""

    private let iconWidth: CGFloat = 24
    private let rowSpacing: CGFloat = 12
    private var dividerInset: CGFloat { 16 + iconWidth + rowSpacing }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // --- Tooltips ---

                Text("Tooltips")
                    .font(.title3.bold())
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)

                Divider()

                Button {
                    hasSeenDebugTooltip = false
                } label: {
                    debugRow(icon: "arrow.counterclockwise", title: "Retrigger demo button tooltip")
                }
                .buttonStyle(.plain)

                Divider()

                // --- Profile ---

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

                Divider()

                // --- Stamps ---

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

                if !stampStore.allDefinitions.isEmpty {
                    Divider().padding(.leading, dividerInset)

                    HStack(spacing: rowSpacing) {
                        Image(systemName: "plus.circle")
                            .frame(width: iconWidth)
                        Picker("Add Stamp", selection: $selectedStampID) {
                            Text("Select…").tag("")
                            ForEach(stampStore.allDefinitions) { definition in
                                Text(definition.displayName).tag(definition.id)
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedStampID) { _, newValue in
                            guard !newValue.isEmpty else { return }
                            stampStore.claimStamp(id: newValue)
                            selectedStampID = ""
                        }
                        Spacer()
                    }
                    .frame(minHeight: 44)
                    .padding(.horizontal, 16)
                }

                Divider()

                // --- Onboarding ---

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

    private func debugRow(icon: String, title: String, tint: Color? = nil) -> some View {
        HStack(spacing: rowSpacing) {
            Image(systemName: icon)
                .foregroundStyle(tint ?? .primary)
                .frame(width: iconWidth)
            Text(title)
            Spacer()
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}
