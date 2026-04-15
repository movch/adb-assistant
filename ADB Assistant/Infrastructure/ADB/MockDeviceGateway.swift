import Foundation

final class MockDeviceGateway: DeviceDiscoveryGateway, DeviceRebootGateway, DeviceScreenshotGateway, DevicePackageGateway, DeviceMetricsGateway {
    func listDeviceIds() -> [String] {
        ["phone", "tablet", "watch", "tv", "auto"]
    }

    func getDevice(forId identifier: String) -> Device {
        Device(identifier: identifier, properties: [
            "ro.product.model": identifier,
            "ro.build.characteristics": identifier
        ])
    }

    func reboot(to _: RebootType, identifier _: String) {}
    func takeScreenshot(identifier _: String, path _: String) {}
    func pull(identifier _: String, fromPath _: String, toPath _: String) {}
    func remove(identifier _: String, path _: String) {}
    func wakeUpDevice(identifier _: String) {}
    func installAPK(identifier _: String, fromPath _: String) {}

    func fetchCPULoad(identifier _: String) -> Double? {
        Double.random(in: 5 ... 75)
    }

    func fetchMemoryUsage(identifier _: String) -> Double? {
        Double.random(in: 30 ... 85)
    }
}
