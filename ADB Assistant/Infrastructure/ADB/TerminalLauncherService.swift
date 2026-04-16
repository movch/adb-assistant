import AppKit
import Foundation

struct TerminalLauncherService {
    func openADBShell(platformToolsPath: String, deviceID: String) -> Bool {
        let command = "cd '\(shellEscape(platformToolsPath))' && ./adb -s '\(shellEscape(deviceID))' shell"
        let scriptBody = """
        #!/bin/zsh
        \(command)
        """

        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("adb-shell-\(UUID().uuidString)").appendingPathExtension("command")

        do {
            try scriptBody.write(to: fileURL, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes(
                [.posixPermissions: 0o755],
                ofItemAtPath: fileURL.path
            )
            return NSWorkspace.shared.open(fileURL)
        } catch {
            return false
        }
    }

    private func shellEscape(_ value: String) -> String {
        value.replacingOccurrences(of: "'", with: "'\\''")
    }
}
