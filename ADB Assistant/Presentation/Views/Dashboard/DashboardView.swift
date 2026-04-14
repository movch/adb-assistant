import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel
    @EnvironmentObject private var deviceListViewModel: DeviceListViewModel
    @State private var presentedSettings: TileID?

    var body: some View {
        Group {
            if deviceListViewModel.selectedDevice == nil {
                EmptyDashboardPlaceholderView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: TileLayoutMetrics.sectionSpacing) {
                        ForEach(dashboardViewModel.makeSections(selectedDevice: deviceListViewModel.selectedDevice)) { section in
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
        .animation(
            .easeInOut(duration: 0.25),
            value: dashboardViewModel.makeSections(selectedDevice: deviceListViewModel.selectedDevice).map(\.id)
        )
        .sheet(item: $presentedSettings) { tile in
            TileSettingsSheet(tile: tile, presentedSettings: $presentedSettings)
                .environmentObject(state)
        }
    }
}
