import Foundation

final class ADBDiscoveryGateway: DeviceDiscoveryGateway {
    private let executor: ADBCommandExecutor

    init(shell: Shell, platformToolsPath: String) {
        executor = ADBCommandExecutor(shell: shell, platformToolsPath: platformToolsPath)
    }

    func listDeviceIds() -> [String] {
        let command = "\(executor.platformToolsPath)/adb devices"
        let deviceIdFilter: (String) -> Bool = { line in
            if line.isEmpty { return false }
            return line
                .components(separatedBy: .whitespaces)[1]
                .contains("device")
        }

        guard let output = try? executor.execute(command) else {
            return []
        }

        return output
            .components(separatedBy: .newlines)
            .filter(deviceIdFilter)
            .map { $0.components(separatedBy: .whitespaces)[0] }
    }

    func getDevice(forId identifier: String) -> Device {
        let deviceProps = getDeviceProps(forId: identifier)
        return Device(identifier: identifier, properties: deviceProps)
    }

    private func getDeviceProps(forId identifier: String) -> [String: String] {
        let command = "\(executor.platformToolsPath)/adb -s \(identifier) shell getprop"
        guard let output = try? executor.execute(command) else {
            return [:]
        }

        return getPropsFromString(output)
    }

    private func getPropsFromString(_ string: String) -> [String: String] {
        guard
            let re = try? NSRegularExpression(pattern: "\\[(.+?)\\]: \\[(.+?)\\]",
                                              options: [])
        else {
            return [:]
        }

        let matches = re.matches(in: string,
                                 options: [],
                                 range: NSRange(location: 0,
                                                length: string.utf16.count))

        var propDict = [String: String]()

        for match in matches {
            let key = (string as NSString).substring(with: match.range(at: 1))
            let value = (string as NSString).substring(with: match.range(at: 2))
            propDict[key] = value
        }

        return propDict
    }
}
