import SwiftUI

struct TileSettingsSheet: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var deviceListViewModel: DeviceListViewModel
    @EnvironmentObject private var capabilityRegistry: CapabilityRegistry
    let tileID: String
    @Binding var presentedSettings: String?

    var body: some View {
        capabilityRegistry.makeSettingsView(
            tileID: tileID,
            context: CapabilityRenderContext(
                deviceList: deviceListViewModel,
                selectedDevice: deviceListViewModel.selectedDevice,
                platformToolsPath: state.platformToolsPath,
                hasConfiguredPlatformTools: state.platformToolsPath?.isEmpty == false,
                screenshotSavePath: state.screenshotSavePath,
                shouldOpenPreview: state.shouldOpenPreview,
                cpuUpdateInterval: state.cpuUpdateInterval,
                setScreenshotSavePath: { state.setScreenshotSavePath($0) },
                setShouldOpenPreview: { state.setShouldOpenPreview($0) },
                setCPUUpdateInterval: { state.cpuUpdateInterval = $0 },
                presentAlert: { title, message in
                    state.alert = AppAlert(title: title, message: message)
                }
            ),
            presentedSettings: $presentedSettings
        )
    }
}

struct ScreenshotSettingsView: View {
    let savePath: String
    let shouldOpenPreview: Bool
    let onChooseFolder: () -> Void
    let onTogglePreview: (Bool) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screenshot Settings")
                .font(.title2)
                .bold()

            SettingsPathRow(
                label: "Save to",
                value: savePath.abbreviatingWithTildeInPath()
            )

            Button("Choose Folder…", action: onChooseFolder)
                .buttonStyle(.bordered)

            Toggle(
                "Open in Preview after capture",
                isOn: Binding(
                    get: { shouldOpenPreview },
                    set: onTogglePreview
                )
            )

            Spacer()

            HStack {
                Spacer()
                Button("Done", action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 360, minHeight: 220)
    }
}

struct CPUMonitorSettingsView: View {
    @State private var interval: Double
    let onIntervalChange: (Double) -> Void
    let onClose: () -> Void

    init(interval: Double, onIntervalChange: @escaping (Double) -> Void, onClose: @escaping () -> Void) {
        _interval = State(initialValue: interval)
        self.onIntervalChange = onIntervalChange
        self.onClose = onClose
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("CPU Monitor")
                .font(.title2)
                .bold()

            Text("Adjust how often CPU usage is sampled from the connected device.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Slider(value: $interval, in: 0.5 ... 5, step: 0.5)
                Text(String(format: "%.1fs", interval))
                    .font(.headline)
                    .frame(width: 60, alignment: .trailing)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Done") {
                    onIntervalChange(interval)
                    onClose()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 360, minHeight: 200)
    }
}

struct PlaceholderSettingsView: View {
    let title: String
    let message: String
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title)
                .font(.title2)
                .bold()

            Text(message)
                .foregroundColor(.secondary)

            Spacer()

            HStack {
                Spacer()
                Button("Close", action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 320, minHeight: 180)
    }
}
