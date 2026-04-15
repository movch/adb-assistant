import Foundation
import SwiftUI

@MainActor
struct MetricsCapabilityProvider: CapabilityUIProvider {
    var section: CapabilitySectionConfig {
        CapabilitySectionConfig(
            id: "metrics",
            title: "Device Metrics",
            subtitle: nil,
            tiles: [CapabilityTileID.cpuUsage, CapabilityTileID.memoryUsage],
            order: 10
        )
    }

    func makeTileView(tileID: String, context _: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView {
        switch tileID {
        case CapabilityTileID.cpuUsage:
            AnyView(CPULoadTileView(presentedSettings: presentedSettings))
        case CapabilityTileID.memoryUsage:
            AnyView(MemoryUsageTileView(presentedSettings: presentedSettings))
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
        default:
            nil
        }
    }
}
