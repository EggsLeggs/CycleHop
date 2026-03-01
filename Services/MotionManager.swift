import CoreMotion

/// Provides device pitch and roll for tilt-based UI (e.g. parallax).
final class MotionManager: ObservableObject {
    @Published var pitch: Double = 0
    @Published var roll: Double = 0

    private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            self.pitch = motion.attitude.pitch
            self.roll = motion.attitude.roll
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
    }
}
