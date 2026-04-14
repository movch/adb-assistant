import Foundation

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var sectionOrder: [TileSectionID] = [
        .metrics,
        .reboot,
        .screenshots,
        .install
    ]

    @Published private(set) var tileOrder: [TileSectionID: [TileID]] = [
        .metrics: [.cpuUsage, .memoryUsage],
        .reboot: [.rebootSystem, .rebootRecovery, .rebootBootloader],
        .screenshots: [.takeScreenshot],
        .install: [.installApk]
    ]

    func makeSections(selectedDevice: Device?) -> [TileSectionConfig] {
        sectionOrder.compactMap { sectionId in
            guard let tiles = tileOrder[sectionId], !tiles.isEmpty else { return nil }
            switch sectionId {
            case .metrics:
                let subtitle = selectedDevice.map { $0.model.isEmpty ? $0.identifier : $0.model }
                return TileSectionConfig(
                    id: sectionId,
                    title: "Device Metrics",
                    subtitle: subtitle,
                    tiles: tiles
                )
            case .reboot:
                return TileSectionConfig(
                    id: sectionId,
                    title: "Reboot",
                    subtitle: "Restart the connected device",
                    tiles: tiles
                )
            case .screenshots:
                return TileSectionConfig(
                    id: sectionId,
                    title: "Screenshots",
                    subtitle: "Capture and manage screenshots",
                    tiles: tiles
                )
            case .install:
                return TileSectionConfig(
                    id: sectionId,
                    title: "Install APK",
                    subtitle: "Deploy packages to the device",
                    tiles: tiles
                )
            }
        }
    }
}
