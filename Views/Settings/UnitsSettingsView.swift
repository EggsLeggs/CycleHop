import SwiftUI

/// Settings screen for distance unit (metric/imperial).
struct UnitsSettingsView: View {
    @AppStorage("distanceUnit") private var distanceUnit = "metric"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Distance Unit")
                    .font(.title3.bold())

                Text("Controls how distances to stations are displayed throughout the app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker("Distance", selection: $distanceUnit) {
                    Text("Kilometres").tag("metric")
                    Text("Miles").tag("imperial")
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.large)
    }
}
