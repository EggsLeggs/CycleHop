import Foundation
import Network

/// Observes network path and exposes whether the device is offline (no connectivity).
final class NetworkMonitor: ObservableObject {
    @Published private(set) var isOffline: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let offline = path.status != .satisfied
            DispatchQueue.main.async {
                self?.isOffline = offline
            }
        }
        monitor.start(queue: queue)
    }
}
