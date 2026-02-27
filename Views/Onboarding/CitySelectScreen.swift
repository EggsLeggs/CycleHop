import SwiftUI

struct CitySelectScreen: View {
    let providers: [any OnboardingCityProvider]
    @Binding var selectedProvider: (any OnboardingCityProvider)?
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("This is a demo. Data is an offline snapshot.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    ForEach(providers, id: \.id) { provider in
                        CityCard(
                            provider: provider,
                            isSelected: selectedProvider?.id == provider.id,
                            onSelect: {
                                if selectedProvider?.id == provider.id {
                                    selectedProvider = nil
                                } else {
                                    selectedProvider = provider
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)

                Text("If your city is missing, add or contribute on GitHub.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .navigationTitle("Choose Your City")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                OnboardingContinueButton(
                    "Continue",
                    isEnabled: selectedProvider != nil
                ) {
                    onContinue()
                }
                .padding(.vertical, 12)
            }
            .background(.regularMaterial)
        }
    }
}
