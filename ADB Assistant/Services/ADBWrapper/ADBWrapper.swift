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

    public func fetchMemoryUsage(identifier: String) -> Double? {
        // Parse /proc/meminfo and compute usage as:
        // used% = 100 * (1 - (MemFree + SwapFree) / MemTotal)
        // Values are reported in kB.
        let command = "\(platformToolsPath)/adb -s \(identifier) shell cat /proc/meminfo"
        let output = shell.execute(command)
        let lines = output.components(separatedBy: .newlines)

        var memTotalKb: Double?
        var memFreeKb: Double?
        var swapFreeKb: Double?

        for line in lines {
            if line.hasPrefix("MemTotal:") {
                memTotalKb = ADBWrapper.parseMeminfoValueKb(from: line)
            } else if line.hasPrefix("MemFree:") {
                memFreeKb = ADBWrapper.parseMeminfoValueKb(from: line)
            } else if line.hasPrefix("SwapFree:") {
                swapFreeKb = ADBWrapper.parseMeminfoValueKb(from: line)
            }
        }

        guard let total = memTotalKb, total > 0 else { return nil }
        let free = (memFreeKb ?? 0) + (swapFreeKb ?? 0)
        let usedFraction = max(0.0, min(1.0, 1.0 - (free / total)))
        return usedFraction * 100.0
    }

    public func fetchCPULoad(identifier: String) -> Double? {
        // Use `top` snapshot to get CPU load; this is generally more reliable across Android versions
        // than parsing `dumpsys cpuinfo`, which often reports misleading totals.
        let command = "\(platformToolsPath)/adb -s \(identifier) shell top -n 1"
        let output = shell.execute(command)
        let lines = output.components(separatedBy: .newlines)

        if let header = preferredCpuHeader(in: lines) {
            if let idleLoad = parseIdleLoad(from: header) {
                return idleLoad
            }
            if let usrSysLoad = parseUsrSysLoad(from: header) {
                return usrSysLoad
            }
        }

        if let fallbackIdle = parseFallbackIdle(in: lines) {
            return fallbackIdle
        }

        return nil
    }

    private func preferredCpuHeader(in lines: [String]) -> String? {
        lines.first { line in
            let lower = line.lowercased()
            return (lower.contains("cpu") || lower.contains("%cpu")) && lower.contains("idle")
        }
    }

    private func parseIdleLoad(from header: String) -> Double? {
        guard let idleAllCpus = matchPercentage(in: header,
                                                pattern: "([0-9.]+)\\s*%?\\s*idle")
        else {
            return nil
        }

        if let normalized = normalizedLoad(idleAllCpus: idleAllCpus, header: header) {
            return normalized
        }

        return clampCpuLoad(100.0 - idleAllCpus)
    }

    private func parseUsrSysLoad(from header: String) -> Double? {
        guard let usr = matchPercentage(in: header,
                                        pattern: "([0-9.]+)\\s*%?\\s*(usr|user)"),
            let sys = matchPercentage(in: header,
                                      pattern: "([0-9.]+)\\s*%?\\s*(sys|system)")
        else {
            return nil
        }

        return clampCpuLoad(usr + sys)
    }

    private func parseFallbackIdle(in lines: [String]) -> Double? {
        guard let idleLine = lines.first(where: { $0.lowercased().contains("idle") }) else {
            return nil
        }

        guard let idle = matchPercentage(in: idleLine,
                                         pattern: "([0-9.]+)\\s*%?\\s*idle")
        else {
            return nil
        }

        return clampCpuLoad(100.0 - idle)
    }

    private func normalizedLoad(idleAllCpus: Double, header: String) -> Double? {
        guard let totalPercentAcrossCpus = matchPercentage(in: header,
                                                           pattern: "([0-9.]+)\\s*%?cpu\\b"),
            totalPercentAcrossCpus >= 100
        else {
            return nil
        }

        let cores = max(1.0, round(totalPercentAcrossCpus / 100.0))
        let normalized = (cores * 100.0 - idleAllCpus) / cores
        return clampCpuLoad(normalized)
    }

    private func matchPercentage(in string: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(string.startIndex ..< string.endIndex, in: string)
        guard let match = regex.firstMatch(in: string, options: [], range: range) else {
            return nil
        }

        let valueString = (string as NSString).substring(with: match.range(at: 1))
        return Double(valueString)
    }

    private func clampCpuLoad(_ value: Double) -> Double {
        max(0, min(100, value))
    }

    private func getDeviceProps(forId identifier: String) -> [String: String] {
        let command = "\(platformToolsPath)/adb -s \(identifier) shell getprop"
        let output = shell.execute(command)

        return getPropsFromString(output)
    }

    private static func parseMeminfoValueKb(from line: String) -> Double? {
        // Expected format like: "MemTotal:       3660000 kB"
        // Extract the numeric token before "kB".
        let tokens = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        // Find first numeric token
        if let token = tokens.first(where: { Double($0) != nil }), let value = Double(token) {
            return value
        }
        // Fallback: regex
        if let re = try? NSRegularExpression(pattern: "([0-9]+)\\s*kB", options: .caseInsensitive) {
            let range = NSRange(location: 0, length: (line as NSString).length)
            if let match = re.firstMatch(in: line, options: [], range: range) {
                let numStr = (line as NSString).substring(with: match.range(at: 1))
                return Double(numStr)
            }
        }
        return nil
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
