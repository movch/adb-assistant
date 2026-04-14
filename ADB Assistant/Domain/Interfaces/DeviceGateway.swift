import Foundation

protocol DeviceGateway: DeviceMetricsGateway {
    func listDeviceIds() -> [String]
    func getDevice(forId identifier: String) -> Device
    func reboot(to type: RebootType, identifier: String)
    func takeScreenshot(identifier: String, path: String)
    func pull(identifier: String, fromPath: String, toPath: String)
    func remove(identifier: String, path: String)
    func wakeUpDevice(identifier: String)
    func installAPK(identifier: String, fromPath path: String)
}

protocol DeviceGatewayFactory {
    func makeGateway(platformToolsPath: String) -> DeviceGateway
}
