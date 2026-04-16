import Foundation
import SwiftUI

@MainActor
struct MetricsCapabilityProvider: CapabilityUIProvider {
    var section: CapabilitySectionConfig {
        CapabilitySectionConfig(
            id: "metrics",
            title: "Device Metrics",
            subtitle: nil,
            tiles: [CapabilityTileID.cpuUsage, CapabilityTileID.memoryUsage, CapabilityTileID.openTerminalShell],
            order: 10
        )
    }

    func makeTileView(tileID: String, context: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView {
        switch tileID {
        case CapabilityTileID.cpuUsage:
            AnyView(CPULoadTileView(presentedSettings: presentedSettings))
        case CapabilityTileID.memoryUsage:
            AnyView(MemoryUsageTileView(presentedSettings: presentedSettings))
        case CapabilityTileID.openTerminalShell:
            AnyView(
                ButtonTileView(
                    icon: "terminal",
                    title: "Open in Terminal",
                    subtitle: "Start adb shell session",
                    isEnabled: context.deviceList.selectedDevice != nil,
                    action: { context.state.openShellForSelectedDevice() },
                    onSettings: { presentedSettings.wrappedValue = tileID }
                )
            )
        default:
            AnyView(EmptyView())
        }
    }

    func makeSettingsView(tileID: String, state: AppState, presentedSettings: Binding<String?>) -> AnyView? {
        switch tileID {
        case CapabilityTileID.cpuUsage:
            AnyView(
                CPUMonitorSettingsView(
                    interval: state.cpuUpdateInterval,
                    onIntervalChange: { state.cpuUpdateInterval = $0 },
                    onClose: { presentedSettings.wrappedValue = nil }
                )
            )
        case CapabilityTileID.memoryUsage:
            AnyView(
                PlaceholderSettingsView(
                    title: "RAM Usage",
                    message: "No configurable options for this tile yet.",
                    onClose: { presentedSettings.wrappedValue = nil }
                )
            )
        case CapabilityTileID.openTerminalShell:
            AnyView(
                PlaceholderSettingsView(
                    title: "Open in Terminal",
                    message: "No configurable options for this tile yet.",
                    onClose: { presentedSettings.wrappedValue = nil }
                )
            )
        default:
            nil
        }
    }
}
