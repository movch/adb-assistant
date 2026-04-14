import Foundation

enum TileSectionID: String, CaseIterable, Identifiable {
    case metrics
    case reboot
    case screenshots
    case install

    var id: String { rawValue }
}

enum TileID: String, CaseIterable, Identifiable {
    case cpuUsage
    case memoryUsage
    case rebootSystem
    case rebootRecovery
    case rebootBootloader
    case takeScreenshot
    case installApk

    var id: String { rawValue }
}

struct TileSectionConfig: Identifiable {
    let id: TileSectionID
    let title: String
    let subtitle: String?
    let tiles: [TileID]
}
