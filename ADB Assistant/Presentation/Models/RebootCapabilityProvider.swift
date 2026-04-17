import Foundation
import SwiftUI

@MainActor
struct RebootCapabilityProvider: CapabilityUIProvider {
    private let useCase: RebootDeviceUseCase

    init(gatewayFactory: GatewayFactory) {
        useCase = RebootDeviceUseCase(gatewayFactory: gatewayFactory)
    }

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
                    action: { reboot(context: context, type: .system) },
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
                    action: { reboot(context: context, type: .recovery) },
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
                    action: { reboot(context: context, type: .bootloader) },
                    onSettings: { presentedSettings.wrappedValue = tileID }
                )
            )
        default:
            return AnyView(EmptyView())
        }
    }

    func makeSettingsView(tileID: String, context _: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView? {
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

    private func reboot(context: CapabilityRenderContext, type: RebootType) {
        guard let device = context.selectedDevice else {
            context.presentAlert("No Device Selected", "Select a device to reboot.")
            return
        }
        guard context.hasConfiguredPlatformTools else {
            context.presentAlert("Missing Platform Tools", "Set the Platform Tools path before issuing ADB commands.")
            return
        }

        let platformToolsPath = context.platformToolsPath
        Task {
            await Task.detached(priority: .userInitiated) {
                _ = useCase.execute(platformToolsPath: platformToolsPath, deviceID: device.identifier, type: type)
            }.value
        }
    }
}
