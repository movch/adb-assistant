import Foundation

final class ADBGatewayFactory: GatewayFactory {
    private let shell: Shell

    init(shell: Shell) {
        self.shell = shell
    }

    func makeDiscoveryGateway(platformToolsPath: String) -> DeviceDiscoveryGateway {
        ADBDiscoveryGateway(shell: shell, platformToolsPath: platformToolsPath)
    }

    func makeRebootGateway(platformToolsPath: String) -> DeviceRebootGateway {
        ADBRebootGateway(shell: shell, platformToolsPath: platformToolsPath)
    }

    func makeScreenshotGateway(platformToolsPath: String) -> DeviceScreenshotGateway {
        ADBScreenshotGateway(shell: shell, platformToolsPath: platformToolsPath)
    }

    func makePackageGateway(platformToolsPath: String) -> DevicePackageGateway {
        ADBPackageGateway(shell: shell, platformToolsPath: platformToolsPath)
    }

    func makeMetricsGateway(platformToolsPath: String) -> DeviceMetricsGateway {
        ADBMetricsGateway(shell: shell, platformToolsPath: platformToolsPath)
    }
}
