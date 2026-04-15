import Foundation

protocol DeviceDiscoveryGateway {
    func listDeviceIds() -> [String]
    func getDevice(forId identifier: String) -> Device
}

protocol DeviceRebootGateway {
    func reboot(to type: RebootType, identifier: String)
}

protocol DeviceScreenshotGateway {
    func takeScreenshot(identifier: String, path: String)
    func pull(identifier: String, fromPath: String, toPath: String)
    func remove(identifier: String, path: String)
}

protocol DevicePackageGateway {
    func wakeUpDevice(identifier: String)
    func installAPK(identifier: String, fromPath path: String)
}

protocol GatewayFactory {
    func makeDiscoveryGateway(platformToolsPath: String) -> DeviceDiscoveryGateway
    func makeRebootGateway(platformToolsPath: String) -> DeviceRebootGateway
    func makeScreenshotGateway(platformToolsPath: String) -> DeviceScreenshotGateway
    func makePackageGateway(platformToolsPath: String) -> DevicePackageGateway
    func makeMetricsGateway(platformToolsPath: String) -> DeviceMetricsGateway
}
