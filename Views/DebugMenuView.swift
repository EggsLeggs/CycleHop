import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var stampStore: StampStore
    @AppStorage("userName") private var userName = ""

    let onRetriggerTooltip: () -> Void
    let onRestartOnboarding: () -> Void

    @State private var selectedStampID = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Tooltips") {
                    Button {
                        onRetriggerTooltip()
                    } label: {
                        Label("Retrigger demo button tooltip", systemImage: "arrow.counterclockwise")
                    }
                }

                Section("Profile") {
                    Button(role: .destructive) {
                        userName = ""
                    } label: {
                        Label {
                            Text("Reset name")
                        } icon: {
                            Image(systemName: "person.crop.circle.badge.minus")
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section("Stamps") {
                    Button(role: .destructive) {
                        stampStore.resetAllStamps()
                    } label: {
                        Label {
                            Text("Reset Stamps")
                        } icon: {
                            Image(systemName: "seal.fill")
                                .foregroundStyle(.red)
                        }
                    }

                    if !stampStore.allDefinitions.isEmpty {
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
                    }
                }

                Section("Onboarding") {
                    Button(role: .destructive) {
                        onRestartOnboarding()
                    } label: {
                        Label {
                                Text("Restart onboarding")
                            } icon: {
                                Image(systemName: "arrow.uturn.backward")
                                    .foregroundStyle(.red)
                            }
                    }
                }
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.regularMaterial)
    }
}
