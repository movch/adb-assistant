import Foundation
import SwiftUI

@MainActor
struct InstallCapabilityProvider: CapabilityUIProvider {
    private let useCase: InstallAPKUseCase

    init(gatewayFactory: GatewayFactory) {
        useCase = InstallAPKUseCase(gatewayFactory: gatewayFactory)
    }

    var section: CapabilitySectionConfig {
        CapabilitySectionConfig(
            id: "install",
            title: "Install APK",
            subtitle: "Deploy packages to the device",
            tiles: [CapabilityTileID.installApk],
            order: 40
        )
    }

    func makeTileView(tileID: String, context: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView {
        guard tileID == CapabilityTileID.installApk else { return AnyView(EmptyView()) }
        return AnyView(
            DragDropTileView(
                presentedSettings: presentedSettings,
                isEnabled: context.selectedDevice != nil,
                onInstall: { install(apkURL: $0, context: context) }
            )
        )
    }

    func makeSettingsView(tileID: String, context _: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView? {
        guard tileID == CapabilityTileID.installApk else { return nil }
        return AnyView(
            PlaceholderSettingsView(
                title: "Install APK",
                message: "Additional settings will appear here in a future update.",
                onClose: { presentedSettings.wrappedValue = nil }
            )
        )
    }

    private func install(apkURL: URL, context: CapabilityRenderContext) {
        guard let device = context.selectedDevice else {
            context.presentAlert("No Device Selected", "Select a device before installing an APK.")
            return
        }
        guard context.hasConfiguredPlatformTools else {
            context.presentAlert("Missing Platform Tools", "Set the Platform Tools path before issuing ADB commands.")
            return
        }
        guard apkURL.pathExtension.lowercased() == "apk" else {
            context.presentAlert("Unsupported File", "Please choose an APK file.")
            return
        }

        let platformToolsPath = context.platformToolsPath
        Task {
            await Task.detached(priority: .userInitiated) {
                _ = useCase.execute(
                    platformToolsPath: platformToolsPath,
                    deviceID: device.identifier,
                    apkURL: apkURL
                )
            }.value
        }
    }
}
