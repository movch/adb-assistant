//
//  ADBWrapper.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 25/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

enum ADBRebootType: String {
    case bootloader, recovery
    case system = ""
}

final class ADBWrapper: ADBWrapperType {
    private let platformToolsPath: String
    private let shell: ShellType

    init(shell: ShellType, platformToolsPath: String) {
        self.platformToolsPath = platformToolsPath
        self.shell = shell
    }

    public func listDeviceIds() -> [String] {
        let command = "\(platformToolsPath)/adb devices"
        let deviceIdFilter: (String) -> Bool = { line in
            if line.isEmpty { return false }
            return line
                .components(separatedBy: .whitespaces)[1]
                .contains("device")
        }

        return shell.execute(command)
            .components(separatedBy: .newlines)
            .filter(deviceIdFilter)
            .map { $0.components(separatedBy: .whitespaces)[0] }
    }

    public func getDevice(forId identifier: String) -> Device {
        let deviceProps = getDeviceProps(forId: identifier)
        return Device(identifier: identifier, properties: deviceProps)
    }

    public func reboot(to: ADBRebootType, identifier: String) {
        let command = "\(platformToolsPath)/adb -s \(identifier) reboot \(to.rawValue)"
        _ = shell.execute(command)
    }

    public func takeScreenshot(identifier: String, path: String) {
        let command = "\(platformToolsPath)/adb -s \(identifier) shell screencap -p \(path)"
        _ = shell.execute(command)
    }

    public func pull(identifier: String, fromPath: String, toPath: String) {
        let command = "\(platformToolsPath)/adb -s \(identifier) pull \(fromPath) \(toPath)"
        _ = shell.execute(command)
    }

    public func remove(identifier: String, path: String) {
        let command = "\(platformToolsPath)/adb -s \(identifier) shell rm -f \(path)"
        _ = shell.execute(command)
    }

    public func wakeUpDevice(identifier: String) {
        let command = "\(platformToolsPath)/adb -s \(identifier) shell input keyevent 82"
        _ = shell.execute(command)
    }

    public func installAPK(identifier: String, fromPath path: String) {
        let command = "\(platformToolsPath)/adb -s \(identifier) install \(path)"
        _ = shell.execute(command)
    }

    private func getDeviceProps(forId identifier: String) -> [String: String] {
        let command = "\(platformToolsPath)/adb -s \(identifier) shell getprop"
        let output = shell.execute(command)

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
