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

        // Try to find a header line that contains overall CPU breakdown with "idle"
        // Examples of possible lines across Android variants:
        // - "%cpu: 5 usr + 3 sys + 0 nic + 90 idle + 0 io + 0 irq + 1 sirq"
        // - "CPU: 5% usr 3% sys 0% nic 90% idle 0% io 0% irq 1% sirq"
        // - "Cpu(s): 5.0%us, 3.0%sy, 0.0%ni, 90.0%id, 0.0%wa, ..."
        // - "800%cpu   6%user   0%nice   6%sys 784%idle   0%iow   3%irq   0%sirq   0%host"
        let lines = output.components(separatedBy: .newlines)

        // Prefer lines that both mention CPU and idle
        if let header = lines.first(where: { line in
            let lower = line.lowercased()
            return (lower.contains("cpu") || lower.contains("%cpu")) && lower.contains("idle")
        }) {
            if let idleRegex = try? NSRegularExpression(pattern: "([0-9.]+)\\s*%?\\s*idle", options: .caseInsensitive) {
                let range = NSRange(header.startIndex ..< header.endIndex, in: header)
                if let match = idleRegex.firstMatch(in: header, options: [], range: range) {
                    let idleString = (header as NSString).substring(with: match.range(at: 1))
                    if let idleAllCpus = Double(idleString) {
                        // Attempt to detect total CPUs from a token like "800%cpu"
                        var normalized: Double?
                        if let totalCpuRegex = try? NSRegularExpression(pattern: "([0-9.]+)\\s*%?cpu\\b", options: .caseInsensitive) {
                            if let totalMatch = totalCpuRegex.firstMatch(in: header, options: [], range: range) {
                                let totalString = (header as NSString).substring(with: totalMatch.range(at: 1))
                                if let totalPercentAcrossCpus = Double(totalString), totalPercentAcrossCpus >= 100 {
                                    let cores = max(1.0, round(totalPercentAcrossCpus / 100.0))
                                    normalized = (cores * 100.0 - idleAllCpus) / cores
                                }
                            }
                        }
                        // If we couldn't infer cores, assume single-CPU scale
                        let load = normalized ?? (100.0 - idleAllCpus)
                        return max(0, min(100, load))
                    }
                }
            }

            // Fallback for devices that omit "idle" but include usr/sys; sum usr+sys
            if let usrRegex = try? NSRegularExpression(pattern: "([0-9.]+)\\s*%?\\s*(usr|user)", options: .caseInsensitive),
               let sysRegex = try? NSRegularExpression(pattern: "([0-9.]+)\\s*%?\\s*(sys|system)", options: .caseInsensitive) {
                let range = NSRange(header.startIndex ..< header.endIndex, in: header)
                let usrMatch = usrRegex.firstMatch(in: header, options: [], range: range)
                let sysMatch = sysRegex.firstMatch(in: header, options: [], range: range)
                let usrStr = usrMatch.map { (header as NSString).substring(with: $0.range(at: 1)) }
                let sysStr = sysMatch.map { (header as NSString).substring(with: $0.range(at: 1)) }
                if let usr = usrStr.flatMap(Double.init), let sys = sysStr.flatMap(Double.init) {
                    return max(0, min(100, usr + sys))
                }
            }
        }

        // As a last resort, look for any "idle" percentage anywhere
        if let anyIdleLine = lines.first(where: { $0.lowercased().contains("idle") }) {
            if let idleRegex = try? NSRegularExpression(pattern: "([0-9.]+)\\s*%?\\s*idle", options: .caseInsensitive) {
                let range = NSRange(anyIdleLine.startIndex ..< anyIdleLine.endIndex, in: anyIdleLine)
                if let match = idleRegex.firstMatch(in: anyIdleLine, options: [], range: range) {
                    let idleString = (anyIdleLine as NSString).substring(with: match.range(at: 1))
                    if let idle = Double(idleString) {
                        return max(0, min(100, 100 - idle))
                    }
                }
            }
        }

        return nil
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
