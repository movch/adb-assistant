import Foundation

final class ADBScreenshotGateway: DeviceScreenshotGateway {
    private let executor: ADBCommandExecutor

    init(shell: Shell, platformToolsPath: String) {
        executor = ADBCommandExecutor(shell: shell, platformToolsPath: platformToolsPath)
    }

    func takeScreenshot(identifier: String, path: String) {
        let command = "\(executor.platformToolsPath)/adb -s \(identifier) shell screencap -p \(path)"
        _ = try? executor.execute(command)
    }

    func pull(identifier: String, fromPath: String, toPath: String) {
        let command = "\(executor.platformToolsPath)/adb -s \(identifier) pull \(fromPath) \(toPath)"
        _ = try? executor.execute(command)
    }

    func remove(identifier: String, path: String) {
        let command = "\(executor.platformToolsPath)/adb -s \(identifier) shell rm -f \(path)"
        _ = try? executor.execute(command)
    }
}
