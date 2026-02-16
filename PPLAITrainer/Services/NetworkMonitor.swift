import Foundation
import Network
import Observation

@Observable
final class NetworkMonitor {
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "NetworkMonitor")
    var isConnected: Bool

    init() {
        let monitor = NWPathMonitor()
        self.monitor = monitor
        self.isConnected = monitor.currentPath.status == .satisfied
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
