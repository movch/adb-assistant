import Foundation

protocol DeviceMetricsGateway {
    func fetchCPULoad(identifier: String) -> Double?
    func fetchMemoryUsage(identifier: String) -> Double?
}
