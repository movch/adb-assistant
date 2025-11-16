import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Layout metrics

enum TileLayoutMetrics {
    static let uiScale: CGFloat = 0.5

    static let baseTileSize: CGFloat = 200
    static let baseTileCornerRadius: CGFloat = 22
    static let baseTileContentPadding: CGFloat = 18
    static let baseGridSpacing: CGFloat = 16
    static let baseSectionSpacing: CGFloat = 28
    static let baseSectionInnerSpacing: CGFloat = 20

    static var tileSize: CGFloat { baseTileSize * uiScale }
    static var tileCornerRadius: CGFloat { baseTileCornerRadius * uiScale }
    static var tileContentPadding: CGFloat { baseTileContentPadding * uiScale }
    static var gridSpacing: CGFloat { baseGridSpacing * uiScale }
    static var sectionSpacing: CGFloat { baseSectionSpacing * uiScale }
    static let sectionHeaderSpacing: CGFloat = 6
    static var sectionInnerSpacing: CGFloat { baseSectionInnerSpacing * uiScale }
    static let contentInsets = EdgeInsets(top: 28, leading: 28, bottom: 40, trailing: 28)
    static let backgroundColor = Color(NSColor.windowBackgroundColor)
}

struct DashboardView: View {
    @EnvironmentObject private var state: AppState
    @State private var presentedSettings: TileID?

    var body: some View {
        Group {
            if state.selectedDevice == nil {
                EmptyDashboardPlaceholderView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: TileLayoutMetrics.sectionSpacing) {
                        ForEach(state.tileSections) { section in
                            TileSectionView(
                                section: section,
                                presentedSettings: $presentedSettings
                            )
                            .transition(
                                .asymmetric(
                                    insertion: .opacity.combined(with: .scale(scale: 0.98)).animation(.easeOut(duration: 0.24)),
                                    removal: .opacity.animation(.easeIn(duration: 0.18))
                                )
                            )
                        }
                    }
                    .padding(TileLayoutMetrics.contentInsets)
                }
                .background(TileLayoutMetrics.backgroundColor)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.tileSections.map(\.id))
        .sheet(item: $presentedSettings) { tile in
            TileSettingsSheet(tile: tile, presentedSettings: $presentedSettings)
                .environmentObject(state)
        }
    }
}

// MARK: - Section

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
        case .memoryUsage:
            MemoryUsageTileView(presentedSettings: $presentedSettings)
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
