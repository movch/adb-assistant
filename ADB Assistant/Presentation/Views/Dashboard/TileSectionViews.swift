import SwiftUI

struct TileSectionView: View {
    let section: CapabilitySectionConfig
    @Binding var presentedSettings: String?

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
                ForEach(section.tiles, id: \.self) { tile in
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
    @EnvironmentObject private var capabilityRegistry: CapabilityRegistry
    let tile: String
    @Binding var presentedSettings: String?

    var body: some View {
        capabilityRegistry.makeTileView(
            tileID: tile,
            context: CapabilityRenderContext(state: state, deviceList: deviceListViewModel),
            presentedSettings: $presentedSettings
        )
    }
}
