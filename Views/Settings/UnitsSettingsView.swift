import SwiftUI

struct UnitsSettingsView: View {
    @AppStorage("distanceUnit") private var distanceUnit = "metric"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Distance Unit")
                    .font(.title3.bold())

                Picker("Distance", selection: $distanceUnit) {
                    Text("Kilometres").tag("metric")
                    Text("Miles").tag("imperial")
                }
                .pickerStyle(.segmented)

                Text("Controls how distances to stations are displayed throughout the app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Units")
        .navigationBarTitleDisplayMode(.large)
    }
}
