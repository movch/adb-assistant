import AppKit
import Foundation
import SwiftUI

@MainActor
struct ScreenshotCapabilityProvider: CapabilityUIProvider {
    private let useCase: TakeScreenshotUseCase

    init(gatewayFactory: GatewayFactory) {
        useCase = TakeScreenshotUseCase(gatewayFactory: gatewayFactory)
    }

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
                subtitle: context.screenshotSavePath.abbreviatingWithTildeInPath(),
                isEnabled: context.selectedDevice != nil,
                action: { takeScreenshot(context: context) },
                onSettings: { presentedSettings.wrappedValue = tileID }
            )
        )
    }

    func makeSettingsView(tileID: String, context: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView? {
        guard tileID == CapabilityTileID.screenshot else { return nil }

        return AnyView(
            ScreenshotSettingsView(
                savePath: context.screenshotSavePath,
                shouldOpenPreview: context.shouldOpenPreview,
                onChooseFolder: {
                    if let newPath = chooseDirectory(initialPath: context.screenshotSavePath) {
                        context.setScreenshotSavePath(newPath)
                    }
                },
                onTogglePreview: { context.setShouldOpenPreview($0) },
                onClose: { presentedSettings.wrappedValue = nil }
            )
        )
    }

    private func takeScreenshot(context: CapabilityRenderContext) {
        guard let device = context.selectedDevice else {
            context.presentAlert("No Device Selected", "Select a device before capturing a screenshot.")
            return
        }
        guard context.hasConfiguredPlatformTools else {
            context.presentAlert("Missing Platform Tools", "Set the Platform Tools path before issuing ADB commands.")
            return
        }

        let request = ScreenshotRequest(
            device: device,
            savePath: context.screenshotSavePath,
            openPreview: context.shouldOpenPreview
        )
        let platformToolsPath = context.platformToolsPath

        Task {
            let result = await Task.detached(priority: .userInitiated) { () -> ScreenshotResult? in
                useCase.execute(platformToolsPath: platformToolsPath, request: request)
            }.value

            guard let result, result.shouldOpenPreview else { return }
            await MainActor.run {
                _ = NSWorkspace.shared.open(result.localFileURL)
            }
        }
    }
}
