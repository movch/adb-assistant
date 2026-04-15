import Foundation
import SwiftUI

@MainActor
struct RebootCapabilityProvider: CapabilityUIProvider {
    var section: CapabilitySectionConfig {
        CapabilitySectionConfig(
            id: "reboot",
            title: "Reboot",
            subtitle: "Restart the connected device",
            tiles: [CapabilityTileID.rebootSystem, CapabilityTileID.rebootRecovery, CapabilityTileID.rebootBootloader],
            order: 20
        )
    }

    func makeTileView(tileID: String, context: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView {
        let isEnabled = context.deviceList.selectedDevice != nil

        switch tileID {
        case CapabilityTileID.rebootSystem:
            return AnyView(
                ButtonTileView(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Restart",
                    subtitle: "Boot into system",
                    isEnabled: isEnabled,
                    action: { context.state.rebootSelectedDevice(to: .system) },
                    onSettings: { presentedSettings.wrappedValue = tileID }
                )
            )
        case CapabilityTileID.rebootRecovery:
            return AnyView(
                ButtonTileView(
                    icon: "cross.case",
                    title: "Recovery",
                    subtitle: "Boot recovery mode",
                    isEnabled: isEnabled,
                    action: { context.state.rebootSelectedDevice(to: .recovery) },
                    onSettings: { presentedSettings.wrappedValue = tileID }
                )
            )
        case CapabilityTileID.rebootBootloader:
            return AnyView(
                ButtonTileView(
                    icon: "bolt.car",
                    title: "Bootloader",
                    subtitle: "Enter bootloader",
                    isEnabled: isEnabled,
                    action: { context.state.rebootSelectedDevice(to: .bootloader) },
                    onSettings: { presentedSettings.wrappedValue = tileID }
                )
            )
        default:
            return AnyView(EmptyView())
        }
    }

    func makeSettingsView(tileID: String, state _: AppState, presentedSettings: Binding<String?>) -> AnyView? {
        switch tileID {
        case CapabilityTileID.rebootSystem, CapabilityTileID.rebootRecovery, CapabilityTileID.rebootBootloader:
            AnyView(
                PlaceholderSettingsView(
                    title: "Reboot",
                    message: "No configurable options for this tile yet.",
                    onClose: { presentedSettings.wrappedValue = nil }
                )
            )
        default:
            nil
        }
    }
}
