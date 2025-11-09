import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Layout metrics

enum TileLayoutMetrics {
    static let tileSize = CGSize(width: 170, height: 170)
    static let tileCornerRadius: CGFloat = 22
    static let tileInnerPadding: CGFloat = 16
    static let tileSpacing: CGFloat = 12
    static let sectionSpacing: CGFloat = 18
    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 24
    static let maxSectionColumns = 4

    // Maximum section width (two tiles plus spacing)
    static let sectionWidth: CGFloat = tileSize.width * 2 + tileSpacing
}

private func tileColumnCount(for section: TileSectionConfig) -> Int {
    switch section.id {
    case .metrics:
        return 1
    default:
        return min(2, max(1, section.tiles.count))
    }
}

private func tileSectionWidth(for section: TileSectionConfig) -> CGFloat {
    let columns = tileColumnCount(for: section)
    let totalSpacing = CGFloat(max(0, columns - 1)) * TileLayoutMetrics.tileSpacing
    return CGFloat(columns) * TileLayoutMetrics.tileSize.width + totalSpacing
}

struct DashboardView: View {
    @EnvironmentObject private var state: AppState
    @State private var presentedSettings: TileID?

    var body: some View {
        if state.selectedDevice == nil {
            EmptyDashboardPlaceholderView()
        } else {
            GeometryReader { proxy in
                let contentWidth = max(
                    TileLayoutMetrics.sectionWidth,
                    proxy.size.width - TileLayoutMetrics.horizontalPadding * 2
                )

                ScrollView {
                    SectionFlowRows(
                        contentWidth: contentWidth,
                        presentedSettings: $presentedSettings
                    )
                    .padding(.horizontal, TileLayoutMetrics.horizontalPadding)
                    .padding(.vertical, TileLayoutMetrics.verticalPadding)
                }
                .background(Color(NSColor.windowBackgroundColor))
            }
            .sheet(item: $presentedSettings) { tile in
                TileSettingsSheet(tile: tile, presentedSettings: $presentedSettings)
                    .environmentObject(state)
            }
        }
    }
}

// MARK: - Section Flow Rows

private struct SectionFlowRows: View {
    @EnvironmentObject private var state: AppState
    let contentWidth: CGFloat
    @Binding var presentedSettings: TileID?

    var body: some View {
        VStack(alignment: .leading, spacing: TileLayoutMetrics.sectionSpacing) {
            ForEach(rows.indices, id: \.self) { index in
                let row = rows[index]

                HStack(alignment: .top, spacing: TileLayoutMetrics.sectionSpacing) {
                    ForEach(row) { section in
                        TileSectionView(
                            section: section,
                            presentedSettings: $presentedSettings
                        )
                    }
                }
                .frame(width: rowWidth(for: row), alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rows: [[TileSectionConfig]] {
        var result: [[TileSectionConfig]] = []
        var currentRow: [TileSectionConfig] = []
        var currentWidth: CGFloat = 0
        let spacing = TileLayoutMetrics.sectionSpacing
        let maxRowWidth = contentWidth

        for section in state.tileSections {
            if currentRow.count >= TileLayoutMetrics.maxSectionColumns {
                result.append(currentRow)
                currentRow = []
                currentWidth = 0
            }

            let sectionWidth = tileSectionWidth(for: section)
            let widthIfAdded = currentRow.isEmpty ? sectionWidth : currentWidth + spacing + sectionWidth

            if currentRow.isEmpty {
                currentRow.append(section)
                currentWidth = sectionWidth
            } else if widthIfAdded <= maxRowWidth {
                currentRow.append(section)
                currentWidth += spacing + sectionWidth
            } else {
                result.append(currentRow)
                currentRow = [section]
                currentWidth = sectionWidth
            }
        }

        if !currentRow.isEmpty {
            result.append(currentRow)
        }

        return result
    }

    private func rowWidth(for row: [TileSectionConfig]) -> CGFloat {
        guard !row.isEmpty else { return 0 }
        let totalTileWidth = row.map { tileSectionWidth(for: $0) }.reduce(0, +)
        let totalSpacing = CGFloat(max(0, row.count - 1)) * TileLayoutMetrics.sectionSpacing
        return totalTileWidth + totalSpacing
    }
}

// MARK: - Section

struct TileSectionView: View {
    @EnvironmentObject private var state: AppState
    let section: TileSectionConfig
    @Binding var presentedSettings: TileID?

    private var gridColumns: [GridItem] {
        Array(
            repeating: GridItem(
                .fixed(TileLayoutMetrics.tileSize.width),
                spacing: TileLayoutMetrics.tileSpacing,
                alignment: .top
            ),
            count: max(1, tileColumnCount(for: section))
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: TileLayoutMetrics.sectionSpacing) {
            // Section header
            VStack(alignment: .leading, spacing: 4) {
                Text(section.title)
                    .font(.title3)
                    .bold()
                if let subtitle = section.subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            // Tiles grid
            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: TileLayoutMetrics.tileSpacing) {
                ForEach(section.tiles) { tile in
                    TileView(tile: tile, presentedSettings: $presentedSettings)
                }
            }
            .padding(.top, TileLayoutMetrics.tileSpacing)
        }
        .frame(width: tileSectionWidth(for: section), alignment: .leading)
    }
}

// MARK: - Tile factory

struct TileView: View {
    @EnvironmentObject private var state: AppState
    let tile: TileID
    @Binding var presentedSettings: TileID?

    var body: some View {
        switch tile {
        case .rebootSystem:
            ButtonTileView(
                icon: "arrow.triangle.2.circlepath",
                title: "Restart",
                subtitle: "Boot into system",
                isEnabled: state.selectedDevice != nil,
                action: { state.rebootSelectedDevice(to: .system) },
                onSettings: { presentedSettings = tile }
            )
        case .rebootRecovery:
            ButtonTileView(
                icon: "cross.case",
                title: "Recovery",
                subtitle: "Boot recovery mode",
                isEnabled: state.selectedDevice != nil,
                action: { state.rebootSelectedDevice(to: .recovery) },
                onSettings: { presentedSettings = tile }
            )
        case .rebootBootloader:
            ButtonTileView(
                icon: "bolt.car",
                title: "Bootloader",
                subtitle: "Enter bootloader",
                isEnabled: state.selectedDevice != nil,
                action: { state.rebootSelectedDevice(to: .bootloader) },
                onSettings: { presentedSettings = tile }
            )
        case .takeScreenshot:
            ButtonTileView(
                icon: "camera.viewfinder",
                title: "Screenshot",
                subtitle: state.screenshotSavePath.abbreviatingWithTildeInPath(),
                isEnabled: state.selectedDevice != nil,
                action: { state.takeScreenshot() },
                onSettings: { presentedSettings = tile }
            )
        case .installApk:
            DragDropTileView(presentedSettings: $presentedSettings)
        case .cpuUsage:
            CPULoadTileView(presentedSettings: $presentedSettings)
        }
    }
}

// MARK: - Tile types

struct EmptyDashboardPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.grid.2x2")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Select a device to manage")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("Connect an Android device via ADB to access controls and metrics.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
