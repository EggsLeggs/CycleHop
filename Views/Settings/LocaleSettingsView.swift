import SwiftUI

struct LocaleSettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = "system"

    private var localeIdentifier: String {
        Locale.current.identifier
    }

    private var languageDisplay: String {
        Locale.current.localizedString(forLanguageCode: Locale.current.language.languageCode?.identifier ?? "") ?? "Unknown"
    }

    private var regionDisplay: String {
        Locale.current.localizedString(forRegionCode: Locale.current.region?.identifier ?? "") ?? "Unknown"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Language")
                        .font(.title3.bold())

                    Text("Choose which language CycleHop uses. Picking \"System Default\" follows your device language.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Picker("App Language", selection: $appLanguage) {
                    Text("System Default").tag("system")
                    Text("English").tag("en")
                    Text("Français").tag("fr")
                }
                .pickerStyle(.segmented)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("System Locale")
                        .font(.title3.bold())

                    Text("Dates, numbers and measurements are formatted based on these system settings.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                localeRow(label: "Identifier", value: localeIdentifier)
                localeRow(label: "Language", value: languageDisplay)
                localeRow(label: "Region", value: regionDisplay)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Locales")
        .navigationBarTitleDisplayMode(.large)
    }

    private func localeRow(label: LocalizedStringKey, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
