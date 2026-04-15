import Foundation

struct RefreshDevicesUseCase {
    let gatewayFactory: GatewayFactory

    func execute(platformToolsPath: String?) -> [Device] {
        guard let platformToolsPath, !platformToolsPath.isEmpty else { return [] }
        let gateway = gatewayFactory.makeDiscoveryGateway(platformToolsPath: platformToolsPath)
        let ids = gateway.listDeviceIds()
        return ids.map { gateway.getDevice(forId: $0) }
    }
}
