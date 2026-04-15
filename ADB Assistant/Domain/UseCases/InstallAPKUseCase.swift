import Foundation

struct InstallAPKUseCase {
    let gatewayFactory: GatewayFactory

    func execute(platformToolsPath: String?, deviceID: String, apkURL: URL) -> Bool {
        guard let platformToolsPath, !platformToolsPath.isEmpty else { return false }
        guard apkURL.pathExtension.lowercased() == "apk" else { return false }

        let gateway = gatewayFactory.makePackageGateway(platformToolsPath: platformToolsPath)
        gateway.installAPK(identifier: deviceID, fromPath: apkURL.path)
        return true
    }
}
