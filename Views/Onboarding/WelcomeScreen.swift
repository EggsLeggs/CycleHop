import SwiftUI

struct WelcomeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(.gray.opacity(0.15))
                .ignoresSafeArea()

            Text("CycleHop")
                .font(.title.bold())
                .padding(.top, 60)
                .padding(.horizontal, 24)
        }
        .safeAreaInset(edge: .bottom) {
            OnboardingContinueButton("Get Started") {
                onContinue()
            }
            .padding(.bottom, 8)
        }
        .navigationBarHidden(true)
    }
}
