import Foundation

final class ADBMetricsGateway: DeviceMetricsGateway {
    private let executor: ADBCommandExecutor

    init(shell: Shell, platformToolsPath: String) {
        executor = ADBCommandExecutor(shell: shell, platformToolsPath: platformToolsPath)
    }

    func fetchMemoryUsage(identifier: String) -> Double? {
        let command = "\(executor.platformToolsPath)/adb -s \(identifier) shell cat /proc/meminfo"
        guard let output = try? executor.execute(command) else {
            return nil
        }
        let lines = output.components(separatedBy: .newlines)

        var memTotalKb: Double?
        var memFreeKb: Double?
        var swapFreeKb: Double?

        for line in lines {
            if line.hasPrefix("MemTotal:") {
                memTotalKb = Self.parseMeminfoValueKb(from: line)
            } else if line.hasPrefix("MemFree:") {
                memFreeKb = Self.parseMeminfoValueKb(from: line)
            } else if line.hasPrefix("SwapFree:") {
                swapFreeKb = Self.parseMeminfoValueKb(from: line)
            }
        }

        guard let total = memTotalKb, total > 0 else { return nil }
        let free = (memFreeKb ?? 0) + (swapFreeKb ?? 0)
        let usedFraction = max(0.0, min(1.0, 1.0 - (free / total)))
        return usedFraction * 100.0
    }

    func fetchCPULoad(identifier: String) -> Double? {
        let command = "\(executor.platformToolsPath)/adb -s \(identifier) shell top -n 1"
        guard let output = try? executor.execute(command) else {
            return nil
        }
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

    private static func parseMeminfoValueKb(from line: String) -> Double? {
        let tokens = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if let token = tokens.first(where: { Double($0) != nil }), let value = Double(token) {
            return value
        }
        if let re = try? NSRegularExpression(pattern: "([0-9]+)\\s*kB", options: .caseInsensitive) {
            let range = NSRange(location: 0, length: (line as NSString).length)
            if let match = re.firstMatch(in: line, options: [], range: range) {
                let numStr = (line as NSString).substring(with: match.range(at: 1))
                return Double(numStr)
            }
        }
        return nil
    }
}
