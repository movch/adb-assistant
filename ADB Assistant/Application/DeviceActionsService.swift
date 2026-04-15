import AppKit
import Foundation

struct DeviceActionsService {
    let rebootDeviceUseCase: RebootDeviceUseCase
    let takeScreenshotUseCase: TakeScreenshotUseCase
    let installAPKUseCase: InstallAPKUseCase

    func reboot(platformToolsPath: String?, deviceID: String, type: RebootType) async {
        await Task.detached(priority: .userInitiated) {
            _ = rebootDeviceUseCase.execute(platformToolsPath: platformToolsPath, deviceID: deviceID, type: type)
        }.value
    }

    func takeScreenshot(
        platformToolsPath: String?,
        device: Device,
        screenshotSavePath: String,
        shouldOpenPreview: Bool
    ) async {
        let result = await Task.detached(priority: .userInitiated) { () -> ScreenshotResult? in
            let request = ScreenshotRequest(device: device, savePath: screenshotSavePath, openPreview: shouldOpenPreview)
            return takeScreenshotUseCase.execute(platformToolsPath: platformToolsPath, request: request)
        }.value

        guard let result, result.shouldOpenPreview else { return }
        await MainActor.run {
            _ = NSWorkspace.shared.open(result.localFileURL)
        }
    }

    func installAPK(platformToolsPath: String?, deviceID: String, apkURL: URL) async {
        await Task.detached(priority: .userInitiated) {
            _ = installAPKUseCase.execute(platformToolsPath: platformToolsPath, deviceID: deviceID, apkURL: apkURL)
        }.value
    }
}
