import Foundation

struct RebootDeviceUseCase {
    let gatewayFactory: DeviceGatewayFactory

    func execute(platformToolsPath: String?, deviceID: String, type: RebootType) -> Bool {
        guard let platformToolsPath, !platformToolsPath.isEmpty else { return false }
        let gateway = gatewayFactory.makeGateway(platformToolsPath: platformToolsPath)
        gateway.reboot(to: type, identifier: deviceID)
        return true
    }
}
