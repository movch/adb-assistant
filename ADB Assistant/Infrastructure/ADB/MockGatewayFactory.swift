import Foundation

final class MockGatewayFactory: GatewayFactory {
    func makeDiscoveryGateway(platformToolsPath _: String) -> DeviceDiscoveryGateway {
        MockDeviceGateway()
    }

    func makeRebootGateway(platformToolsPath _: String) -> DeviceRebootGateway {
        MockDeviceGateway()
    }

    func makeScreenshotGateway(platformToolsPath _: String) -> DeviceScreenshotGateway {
        MockDeviceGateway()
    }

    func makePackageGateway(platformToolsPath _: String) -> DevicePackageGateway {
        MockDeviceGateway()
    }

    func makeMetricsGateway(platformToolsPath _: String) -> DeviceMetricsGateway {
        MockDeviceGateway()
    }
}
