import Foundation
import SwiftUI

@MainActor
struct ScreenshotCapabilityProvider: CapabilityUIProvider {
    var section: CapabilitySectionConfig {
        CapabilitySectionConfig(
            id: "screenshots",
            title: "Screenshots",
            subtitle: "Capture and manage screenshots",
            tiles: [CapabilityTileID.screenshot],
            order: 30
        )
    }

    func makeTileView(tileID: String, context: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView {
        guard tileID == CapabilityTileID.screenshot else { return AnyView(EmptyView()) }

        return AnyView(
            ButtonTileView(
                icon: "camera.viewfinder",
                title: "Screenshot",
                subtitle: context.state.screenshotSavePath.abbreviatingWithTildeInPath(),
                isEnabled: context.deviceList.selectedDevice != nil,
                action: { context.state.takeScreenshot() },
                onSettings: { presentedSettings.wrappedValue = tileID }
            )
        )
    }

    func makeSettingsView(tileID: String, state: AppState, presentedSettings: Binding<String?>) -> AnyView? {
        guard tileID == CapabilityTileID.screenshot else { return nil }

        return AnyView(
            ScreenshotSettingsView(
                savePath: state.screenshotSavePath,
                shouldOpenPreview: state.shouldOpenPreview,
                onChooseFolder: {
                    if let newPath = chooseDirectory(initialPath: state.screenshotSavePath) {
                        state.setScreenshotSavePath(newPath)
                    }
                },
                onTogglePreview: { state.setShouldOpenPreview($0) },
                onClose: { presentedSettings.wrappedValue = nil }
            )
        )
    }
}
