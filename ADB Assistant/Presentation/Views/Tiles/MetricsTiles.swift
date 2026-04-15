import SwiftUI

struct CPULoadTileView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var deviceList: DeviceListViewModel
    @EnvironmentObject private var metrics: MetricsViewModel
    @Binding var presentedSettings: String?

    private var latestValue: Double? {
        metrics.cpuHistory.last?.value
    }

    var body: some View {
        TileCard(
            iconName: nil,
            accentColor: .purple,
            title: "CPU Usage",
            subtitle: latestText,
            isEnabled: deviceList.selectedDevice != nil,
            isActive: false,
            showsSettingsButton: false,
            onTap: { presentedSettings = CapabilityTileID.cpuUsage },
            onSettings: {},
            content: {
                CPUGraphView(samples: metrics.cpuHistory)
                    .frame(height: 30)
            }
        )
    }

    private var latestText: String? {
        guard let value = latestValue else { return "Awaiting data…" }
        return String(format: "%.1f%% · every %.1fs", value, state.cpuUpdateInterval)
    }
}

struct MemoryUsageTileView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var deviceList: DeviceListViewModel
    @EnvironmentObject private var metrics: MetricsViewModel
    @Binding var presentedSettings: String?

    private var latestValue: Double? {
        metrics.memoryHistory.last?.value
    }

    var body: some View {
        TileCard(
            iconName: nil,
            accentColor: .teal,
            title: "RAM Usage",
            subtitle: latestText,
            isEnabled: deviceList.selectedDevice != nil,
            isActive: false,
            showsSettingsButton: false,
            onTap: { presentedSettings = CapabilityTileID.memoryUsage },
            onSettings: {},
            content: {
                MemoryGraphView(samples: metrics.memoryHistory)
                    .frame(height: 30)
            }
        )
    }

    private var latestText: String? {
        guard let value = latestValue else { return "Awaiting data…" }
        return String(format: "%.1f%% · every %.1fs", value, state.cpuUpdateInterval)
    }
}
