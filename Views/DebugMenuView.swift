import SwiftUI

struct DebugMenuView: View {
    @Environment(\.dismiss) private var dismiss

    let onRetriggerTooltip: () -> Void
    let onRestartOnboarding: () -> Void

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
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
