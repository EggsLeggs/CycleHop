import SwiftUI

/// One-time explainer sheet shown after onboarding to explain mock location mode.
struct MockLocationExplainerSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "mappin.and.ellipse.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)

            VStack(spacing: 12) {
                Text(NSLocalizedString("mock_location_explainer_title", bundle: .localized, comment: ""))
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString("mock_location_explainer_body", bundle: .localized, comment: ""))
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text(NSLocalizedString("mock_location_explainer_cta", bundle: .localized, comment: ""))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
}
