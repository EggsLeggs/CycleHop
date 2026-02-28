import SwiftUI

struct LocaleSettingsView: View {
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
            VStack(alignment: .leading, spacing: 16) {
                localeRow(label: "Identifier", value: localeIdentifier)
                localeRow(label: "Language", value: languageDisplay)
                localeRow(label: "Region", value: regionDisplay)

                Text("The app uses your system locale for formatting dates, numbers and units.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("Locales")
        .navigationBarTitleDisplayMode(.large)
    }

    private func localeRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
