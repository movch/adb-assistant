import Foundation

struct FetchDeviceMetricsUseCase {
    let gatewayFactory: GatewayFactory

    func fetchCPU(platformToolsPath: String?, deviceID: String) -> Double? {
        guard let platformToolsPath, !platformToolsPath.isEmpty else { return nil }
        let gateway = gatewayFactory.makeMetricsGateway(platformToolsPath: platformToolsPath)
        return gateway.fetchCPULoad(identifier: deviceID)
    }

    func fetchMemory(platformToolsPath: String?, deviceID: String) -> Double? {
        guard let platformToolsPath, !platformToolsPath.isEmpty else { return nil }
        let gateway = gatewayFactory.makeMetricsGateway(platformToolsPath: platformToolsPath)
        return gateway.fetchMemoryUsage(identifier: deviceID)
    }
}
