import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Layout metrics

enum TileLayoutMetrics {
    static let tileMinWidth: CGFloat = 212
    static let tileMinHeight: CGFloat = 188
    static let tileCornerRadius: CGFloat = 22
    static let tileContentPadding: CGFloat = 18
    static let gridSpacing: CGFloat = 16
    static let sectionSpacing: CGFloat = 28
    static let sectionMinWidth: CGFloat = 240
    static let sectionMaxWidth: CGFloat = 340
    static let sectionHeaderSpacing: CGFloat = 6
    static let sectionInnerSpacing: CGFloat = 20
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
                GeometryReader { proxy in
                    let columns = sectionColumns(for: proxy.size.width)

                    ScrollView {
                        LazyVGrid(
                            columns: columns,
                            alignment: .leading,
                            spacing: TileLayoutMetrics.sectionSpacing
                        ) {
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
        }
        .animation(.easeInOut(duration: 0.25), value: state.tileSections.map(\.id))
        .sheet(item: $presentedSettings) { tile in
            TileSettingsSheet(tile: tile, presentedSettings: $presentedSettings)
                .environmentObject(state)
        }
    }

    private func sectionColumns(for width: CGFloat) -> [GridItem] {
        let horizontalInsets = TileLayoutMetrics.contentInsets.leading + TileLayoutMetrics.contentInsets.trailing
        let availableWidth = max(width - horizontalInsets, TileLayoutMetrics.sectionMinWidth)
        let minWidth = TileLayoutMetrics.sectionMinWidth
        let maxWidth = TileLayoutMetrics.sectionMaxWidth

        let column = GridItem(
            .adaptive(minimum: minWidth, maximum: maxWidth),
            spacing: TileLayoutMetrics.sectionSpacing,
            alignment: .top
        )

        // Force single column if very narrow to avoid clipping.
        if availableWidth <= minWidth + TileLayoutMetrics.sectionSpacing {
            return [GridItem(.flexible(minimum: minWidth, maximum: maxWidth), spacing: TileLayoutMetrics.sectionSpacing, alignment: .top)]
        }

        return [column]
    }
}

// MARK: - Section

struct TileSectionView: View {
    let section: TileSectionConfig
    @Binding var presentedSettings: TileID?

    private var gridColumns: [GridItem] {
        [
            GridItem(
                .adaptive(
                    minimum: TileLayoutMetrics.tileMinWidth
                ),
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
