import Foundation

final class ADBPackageGateway: DevicePackageGateway {
    private let executor: ADBCommandExecutor

    init(shell: Shell, platformToolsPath: String) {
        executor = ADBCommandExecutor(shell: shell, platformToolsPath: platformToolsPath)
    }

    func wakeUpDevice(identifier: String) {
        let command = "\(executor.platformToolsPath)/adb -s \(identifier) shell input keyevent 82"
        _ = try? executor.execute(command)
    }

    func installAPK(identifier: String, fromPath path: String) {
        let command = "\(executor.platformToolsPath)/adb -s \(identifier) install \(path)"
        _ = try? executor.execute(command)
    }
}
