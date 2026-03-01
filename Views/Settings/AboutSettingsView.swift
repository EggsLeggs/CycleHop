import SwiftUI

/// About screen: app description, GitHub link, acknowledgements (OSM, etc.).
struct AboutSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("CycleHop connects you to bike-share systems so you can find bikes and docks wherever you go. Built as a Swift Student Challenge submission, it works fully offline and supports multiple cities.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Link(
                    "View on GitHub →",
                    destination: URL(string: "https://github.com/EggsLeggs/CycleHop")!
                )
                .font(.body.bold())
                .tint(.blue)

                // MARK: Acknowledgements

                Text("Acknowledgements")
                    .font(.title3.bold())
                    .padding(.top, 8)

                creditSection(
                    title: "OpenStreetMap",
                    license: "Open Data Commons Open Database License (ODbL)",
                    description: "Map tiles bundled for offline use are rendered from OpenStreetMap data. OSM is a collaborative project providing freely usable geographic data.",
                    link: ("openstreetmap.org/copyright", "https://www.openstreetmap.org/copyright")
                )

                creditSection(
                    title: "SVGLoader",
                    license: "Public domain / community snippet",
                    description: "A lightweight WKWebView-based SVG-to-UIImage renderer adapted from open-source Swift community code. Used to render crisp SVG illustrations at any display scale.",
                    link: nil
                )

                Text(NSLocalizedString("about_bike_share_section", bundle: .localized, comment: ""))
                    .font(.title3.bold())
                    .padding(.top, 8)

                creditSection(
                    title: NSLocalizedString("about_credit_citibike_title", bundle: .localized, comment: ""),
                    license: NSLocalizedString("about_credit_citibike_license", bundle: .localized, comment: ""),
                    description: NSLocalizedString("about_credit_citibike_description", bundle: .localized, comment: ""),
                    link: (NSLocalizedString("about_credit_citibike_link", bundle: .localized, comment: ""), "https://citibikenyc.com")
                )

                creditSection(
                    title: NSLocalizedString("about_credit_santander_title", bundle: .localized, comment: ""),
                    license: NSLocalizedString("about_credit_santander_license", bundle: .localized, comment: ""),
                    description: "BikePoint station data for Santander Cycles in London. © Transport for London. Used under TfL’s data terms.",
                    link: ("tfl.gov.uk", "https://tfl.gov.uk")
                )

                creditSection(
                    title: NSLocalizedString("about_credit_velib_title", bundle: .localized, comment: ""),
                    license: NSLocalizedString("about_credit_velib_license", bundle: .localized, comment: ""),
                    description: NSLocalizedString("about_credit_velib_description", bundle: .localized, comment: ""),
                    link: (NSLocalizedString("about_credit_velib_link", bundle: .localized, comment: ""), "https://www.velib-metropole.fr")
                )
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: Credit row

    private func creditSection(
        title: String,
        license: String,
        description: String,
        link: (label: String, url: String)?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)

            Text(license)
                .font(.caption)
                .foregroundStyle(.secondary)
                .italic()

            Text(description)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let link, let url = URL(string: link.url) {
                Link(link.label, destination: url)
                    .font(.footnote.bold())
                    .tint(.blue)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
