import Foundation

@MainActor
final class DeviceEventsCoordinator {
    private let eventsSourceFactory: DeviceEventsSourceFactory
    private var deviceEventsSource: DeviceEventsSource?

    init(eventsSourceFactory: DeviceEventsSourceFactory) {
        self.eventsSourceFactory = eventsSourceFactory
    }

    func startWatching(onDevicesChanged: @escaping @MainActor () -> Void) {
        let source = eventsSourceFactory.makeSource()
        source.onDevicesChanged = {
            Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await onDevicesChanged()
            }
        }
        deviceEventsSource = source
    }

    func stopWatching() {
        deviceEventsSource = nil
    }
}
