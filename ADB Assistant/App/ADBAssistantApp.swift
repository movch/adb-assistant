import SwiftUI

@main
struct ADBAssistantApp: App {
    @StateObject private var state: AppState

    init() {
        let defaults = Defaults()
        let shell = Shell()
        _state = StateObject(wrappedValue: AppState(shell: shell, defaults: defaults))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
        }
    }
}
