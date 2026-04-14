import SwiftUI

struct TileSectionView: View {
    let section: TileSectionConfig
    @Binding var presentedSettings: TileID?

    private var gridColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: TileLayoutMetrics.tileSize, maximum: TileLayoutMetrics.tileSize),
                spacing: TileLayoutMetrics.gridSpacing,
                alignment: .top
            )
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TileLayoutMetrics.sectionInnerSpacing) {
            VStack(alignment: .leading, spacing: TileLayoutMetrics.sectionHeaderSpacing) {
                Text(section.title)
                    .font(.title3.weight(.semibold))
                if let subtitle = section.subtitle {
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            LazyVGrid(
                columns: gridColumns,
                alignment: .leading,
                spacing: TileLayoutMetrics.gridSpacing
            ) {
                ForEach(section.tiles) { tile in
                    TileView(tile: tile, presentedSettings: $presentedSettings)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TileView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var deviceListViewModel: DeviceListViewModel
    let tile: TileID
    @Binding var presentedSettings: TileID?

    var body: some View {
        switch tile {
        case .rebootSystem:
            ButtonTileView(
                icon: "arrow.triangle.2.circlepath",
                title: "Restart",
                subtitle: "Boot into system",
                isEnabled: deviceListViewModel.selectedDevice != nil,
                action: { state.rebootSelectedDevice(to: .system) },
                onSettings: { presentedSettings = tile }
            )
        case .rebootRecovery:
            ButtonTileView(
                icon: "cross.case",
                title: "Recovery",
                subtitle: "Boot recovery mode",
                isEnabled: deviceListViewModel.selectedDevice != nil,
                action: { state.rebootSelectedDevice(to: .recovery) },
                onSettings: { presentedSettings = tile }
            )
        case .rebootBootloader:
            ButtonTileView(
                icon: "bolt.car",
                title: "Bootloader",
                subtitle: "Enter bootloader",
                isEnabled: deviceListViewModel.selectedDevice != nil,
                action: { state.rebootSelectedDevice(to: .bootloader) },
                onSettings: { presentedSettings = tile }
            )
        case .takeScreenshot:
            ButtonTileView(
                icon: "camera.viewfinder",
                title: "Screenshot",
                subtitle: state.screenshotSavePath.abbreviatingWithTildeInPath(),
                isEnabled: deviceListViewModel.selectedDevice != nil,
                action: { state.takeScreenshot() },
                onSettings: { presentedSettings = tile }
            )
        case .installApk:
            DragDropTileView(presentedSettings: $presentedSettings)
        case .cpuUsage:
            CPULoadTileView(presentedSettings: $presentedSettings)
        case .memoryUsage:
            MemoryUsageTileView(presentedSettings: $presentedSettings)
        }
    }
}
