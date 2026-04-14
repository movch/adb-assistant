import Foundation

struct InstallAPKUseCase {
    let gatewayFactory: DeviceGatewayFactory

    func execute(platformToolsPath: String?, deviceID: String, apkURL: URL) -> Bool {
        guard let platformToolsPath, !platformToolsPath.isEmpty else { return false }
        guard apkURL.pathExtension.lowercased() == "apk" else { return false }

        let gateway = gatewayFactory.makeGateway(platformToolsPath: platformToolsPath)
        gateway.installAPK(identifier: deviceID, fromPath: apkURL.path)
        return true
    }
}
