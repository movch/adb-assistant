import Foundation

struct ScreenshotRequest {
    let device: Device
    let savePath: String
    let openPreview: Bool
}

struct ScreenshotResult {
    let shouldOpenPreview: Bool
    let localFileURL: URL
}

struct TakeScreenshotUseCase {
    let gatewayFactory: DeviceGatewayFactory

    func execute(platformToolsPath: String?, request: ScreenshotRequest) -> ScreenshotResult? {
        guard let platformToolsPath, !platformToolsPath.isEmpty else { return nil }

        let modelName = request.device.model.isEmpty ? request.device.identifier : request.device.model
        let filename = "\(modelName.toFilenameString())-\(Date().toFilenameString()).png"
        let tempDevicePath = "/sdcard/\(filename)"
        let expandedSavePath = NSString(string: request.savePath).expandingTildeInPath

        let gateway = gatewayFactory.makeGateway(platformToolsPath: platformToolsPath)
        gateway.takeScreenshot(identifier: request.device.identifier, path: tempDevicePath)
        gateway.pull(identifier: request.device.identifier, fromPath: tempDevicePath, toPath: expandedSavePath)
        gateway.remove(identifier: request.device.identifier, path: tempDevicePath)

        let localFileURL = URL(fileURLWithPath: expandedSavePath).appendingPathComponent(filename)
        return ScreenshotResult(shouldOpenPreview: request.openPreview, localFileURL: localFileURL)
    }
}
