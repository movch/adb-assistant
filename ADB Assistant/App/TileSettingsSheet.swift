import SwiftUI

struct TileSettingsSheet: View {
    @EnvironmentObject private var state: AppState
    let tile: TileID
    @Binding var presentedSettings: TileID?

    var body: some View {
        switch tile {
        case .takeScreenshot:
            ScreenshotSettingsView(
                savePath: state.screenshotSavePath,
                shouldOpenPreview: state.shouldOpenPreview,
                onChooseFolder: chooseScreenshotFolder,
                onTogglePreview: { state.setShouldOpenPreview($0) },
                onClose: close
            )
        case .cpuUsage:
            CPUMonitorSettingsView(
                interval: state.cpuUpdateInterval,
                onIntervalChange: { state.cpuUpdateInterval = $0 },
                onClose: close
            )
        case .installApk:
            PlaceholderSettingsView(
                title: "Install APK",
                message: "Additional settings will appear here in a future update.",
                onClose: close
            )
        case .rebootSystem, .rebootRecovery, .rebootBootloader:
            PlaceholderSettingsView(
                title: "Reboot",
                message: "No configurable options for this tile yet.",
                onClose: close
            )
        }
    }

    private func chooseScreenshotFolder() {
        if let newPath = chooseDirectory(initialPath: state.screenshotSavePath) {
            state.setScreenshotSavePath(newPath)
        }
    }

    private func close() {
        presentedSettings = nil
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
                Slider(value: $interval, in: 0.5...5, step: 0.5)
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
