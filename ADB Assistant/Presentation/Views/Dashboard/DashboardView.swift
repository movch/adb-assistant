import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var capabilityRegistry: CapabilityRegistry
    @EnvironmentObject private var deviceListViewModel: DeviceListViewModel
    @State private var presentedSettings: String?

    private var sections: [CapabilitySectionConfig] {
        capabilityRegistry.sections.map { section in
            if section.id == "metrics" {
                let subtitle = deviceListViewModel.selectedDevice.map { $0.model.isEmpty ? $0.identifier : $0.model }
                return CapabilitySectionConfig(
                    id: section.id,
                    title: section.title,
                    subtitle: subtitle,
                    tiles: section.tiles,
                    order: section.order
                )
            }
            return section
        }
    }

    var body: some View {
        Group {
            if deviceListViewModel.selectedDevice == nil {
                EmptyDashboardPlaceholderView()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: TileLayoutMetrics.sectionSpacing) {
                        ForEach(sections) { section in
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
            value: sections.map(\.id)
        )
        .sheet(
            isPresented: Binding(
                get: { presentedSettings != nil },
                set: { isPresented in
                    if !isPresented {
                        presentedSettings = nil
                    }
                }
            )
        ) {
            if let tile = presentedSettings {
                TileSettingsSheet(tileID: tile, presentedSettings: $presentedSettings)
                    .environmentObject(state)
                    .environmentObject(deviceListViewModel)
                    .environmentObject(capabilityRegistry)
            }
        }
    }
}
