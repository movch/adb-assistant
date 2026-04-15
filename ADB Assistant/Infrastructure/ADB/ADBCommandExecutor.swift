import Foundation

struct ADBCommandExecutor {
    let platformToolsPath: String
    private let shell: Shell

    init(shell: Shell, platformToolsPath: String) {
        self.platformToolsPath = platformToolsPath
        self.shell = shell
    }

    func execute(_ command: String) throws -> String {
        try shell.execute(command)
    }
}
