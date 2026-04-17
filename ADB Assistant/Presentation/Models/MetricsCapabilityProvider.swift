import Foundation
import SwiftUI

@MainActor
struct MetricsCapabilityProvider: CapabilityUIProvider {
    private let terminalLauncherService: TerminalLauncherService

    init(terminalLauncherService: TerminalLauncherService) {
        self.terminalLauncherService = terminalLauncherService
    }

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
            AnyView(
                CPULoadTileView(
                    presentedSettings: presentedSettings,
                    interval: context.cpuUpdateInterval
                )
            )
        case CapabilityTileID.memoryUsage:
            AnyView(
                MemoryUsageTileView(
                    presentedSettings: presentedSettings,
                    interval: context.cpuUpdateInterval
                )
            )
        case CapabilityTileID.openTerminalShell:
            AnyView(
                ButtonTileView(
                    icon: "terminal",
                    title: "Open in Terminal",
                    subtitle: "Start adb shell session",
                    isEnabled: context.selectedDevice != nil,
                    action: {
                        guard let device = context.selectedDevice else {
                            context.presentAlert("No Device Selected", "Select a device before opening an adb shell session.")
                            return
                        }
                        guard context.hasConfiguredPlatformTools, let platformToolsPath = context.platformToolsPath else {
                            context.presentAlert("Missing Platform Tools", "Set the Platform Tools path before opening adb shell.")
                            return
                        }

                        let didOpen = terminalLauncherService.openADBShell(
                            platformToolsPath: platformToolsPath,
                            deviceID: device.identifier
                        )
                        if !didOpen {
                            context.presentAlert(
                                "Unable to Launch Terminal",
                                "Could not open Terminal with an adb shell session."
                            )
                        }
                    },
                    onSettings: { presentedSettings.wrappedValue = tileID }
                )
            )
        default:
            AnyView(EmptyView())
        }
    }

    func makeSettingsView(tileID: String, context: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView? {
        switch tileID {
        case CapabilityTileID.cpuUsage:
            AnyView(
                CPUMonitorSettingsView(
                    interval: context.cpuUpdateInterval,
                    onIntervalChange: { context.setCPUUpdateInterval($0) },
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
