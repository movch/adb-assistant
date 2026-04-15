import Foundation

final class ADBRebootGateway: DeviceRebootGateway {
    private let executor: ADBCommandExecutor

    init(shell: Shell, platformToolsPath: String) {
        executor = ADBCommandExecutor(shell: shell, platformToolsPath: platformToolsPath)
    }

    func reboot(to: RebootType, identifier: String) {
        let command = "\(executor.platformToolsPath)/adb -s \(identifier) reboot \(to.rawValue)"
        _ = try? executor.execute(command)
    }
}
