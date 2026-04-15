import Foundation
import SwiftUI

@MainActor
struct InstallCapabilityProvider: CapabilityUIProvider {
    var section: CapabilitySectionConfig {
        CapabilitySectionConfig(
            id: "install",
            title: "Install APK",
            subtitle: "Deploy packages to the device",
            tiles: [CapabilityTileID.installApk],
            order: 40
        )
    }

    func makeTileView(tileID: String, context _: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView {
        guard tileID == CapabilityTileID.installApk else { return AnyView(EmptyView()) }
        return AnyView(DragDropTileView(presentedSettings: presentedSettings))
    }

    func makeSettingsView(tileID: String, state _: AppState, presentedSettings: Binding<String?>) -> AnyView? {
        guard tileID == CapabilityTileID.installApk else { return nil }
        return AnyView(
            PlaceholderSettingsView(
                title: "Install APK",
                message: "Additional settings will appear here in a future update.",
                onClose: { presentedSettings.wrappedValue = nil }
            )
        )
    }
}
