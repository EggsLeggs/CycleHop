import SwiftUI

/// Full-width primary button for onboarding steps (Continue, Get Started, etc.).
struct OnboardingContinueButton: View {
    let title: LocalizedStringKey
    let isEnabled: Bool
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    init(_ title: LocalizedStringKey = "Continue", isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    private var buttonBackground: Color {
        if !isEnabled {
            return colorScheme == .dark ? Color.white.opacity(0.3) : Color.gray.opacity(0.5)
        }
        return colorScheme == .dark ? Color.white : Color.black
    }

    private var textColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isEnabled ? textColor : (colorScheme == .dark ? Color.black.opacity(0.4) : Color.white))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(buttonBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!isEnabled)
        .padding(.horizontal)
    }
}
