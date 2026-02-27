import SwiftUI

@main
struct CycleHopApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    #if DEBUG
                    Task { await TestSuite.run() }
                    #endif
                }
        }
    }
}
