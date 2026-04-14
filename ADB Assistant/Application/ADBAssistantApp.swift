import SwiftUI

@main
struct ADBAssistantApp: App {
    @StateObject private var state: AppState

    init() {
        let preferences = Defaults()
        let shell = Bash()
        let gatewayFactory = ADBDeviceGatewayFactory(shell: shell)
        let eventsSourceFactory = USBWatcherFactory()
        _state = StateObject(
            wrappedValue: AppState(
                gatewayFactory: gatewayFactory,
                preferences: preferences,
                eventsSourceFactory: eventsSourceFactory
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .environmentObject(state.deviceListViewModel)
                .environmentObject(state.metricsViewModel)
                .environmentObject(state.dashboardViewModel)
        }
    }
}
