import AppKit
import SwiftUI
import UniformTypeIdentifiers

// MARK: - Sidebar

struct SidebarView: View {
    @EnvironmentObject private var state: AppState
    @Binding var showPreferences: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            deviceList
        }
    }

    private var header: some View {
        HStack {
            Text("Devices")
                .font(.headline)
            Spacer()
            Button(
                action: { state.refreshDevices() },
                label: {
                    Image(systemName: "arrow.clockwise")
                }
            )
            .buttonStyle(.plain)
            .help("Refresh connected devices")

            Button(
                action: { showPreferences = true },
                label: {
                    Image(systemName: "gearshape")
                }
            )
            .buttonStyle(.plain)
            .help("Open preferences")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private var deviceList: some View {
        ZStack {
            List(selection: $state.selectedDeviceID) {
                ForEach(state.devices) { device in
                    NavigationLink(
                        destination: ActionsView(device: device),
                        tag: device.identifier,
                        selection: $state.selectedDeviceID
                    ) {
                        DeviceRow(device: device)
                    }
                }
            }
            .listStyle(SidebarListStyle())

            if state.devices.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "iphone.slash")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No devices detected")
                        .foregroundColor(.secondary)
                    Button("Refresh") {
                        state.refreshDevices()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
        }
    }
}

struct DeviceRow: View {
    let device: Device

    var body: some View {
        HStack(spacing: 8) {
            Image(device.type.imageName)
                .resizable()
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(device.model.isEmpty ? "Unknown device" : device.model)
                    .font(.body)
                Text(device.identifier)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DetailPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Select a device")
                .font(.title3)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Actions

struct ActionsView: View {
    @EnvironmentObject private var state: AppState
    let device: Device
    @State private var isDropTarget = false

    private var dropTypes: [UTType] {
        if let apk = UTType(filenameExtension: "apk") {
            return [apk, .fileURL]
        }
        return [.fileURL]
    }

    var body: some View {
        ScrollView {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 24) {
                    RebootSection(device: device)
                    ScreenshotSection()
                    InstallSection(isDropTarget: $isDropTarget, dropTypes: dropTypes)
                }
                .frame(maxWidth: 540, alignment: .leading)

                Spacer(minLength: 0)
            }
            .padding(24)
        }
        .navigationTitle(device.model.isEmpty ? device.identifier : device.model)
    }
}

struct RebootSection: View {
    @EnvironmentObject private var state: AppState
    let device: Device

    var body: some View {
        Section {
            Text("Reboot")
                .font(.title2)
            Text("Restart \(displayName) into:")
                .foregroundColor(.secondary)

            HStack {
                Button("System") {
                    state.rebootSelectedDevice(to: .system)
                }
                Button("Recovery") {
                    state.rebootSelectedDevice(to: .recovery)
                }
                Button("Bootloader") {
                    state.rebootSelectedDevice(to: .bootloader)
                }
            }
            .buttonStyle(.bordered)
        }
    }

    private var displayName: String {
        device.model.isEmpty ? device.identifier : device.model
    }
}

struct ScreenshotSection: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        Section {
            Text("Screenshots")
                .font(.title2)

            VStack(alignment: .leading, spacing: 12) {
                PathRow(
                    label: "Save to",
                    value: state.screenshotSavePath.abbreviatingWithTildeInPath()
                )

                HStack {
                    Button("Choose Folder…") {
                        if let newPath = chooseDirectory(initialPath: state.screenshotSavePath) {
                            state.setScreenshotSavePath(newPath)
                        }
                    }
                    Button("Capture Screenshot") {
                        state.takeScreenshot()
                    }
                    .buttonStyle(.bordered)
                }

                Toggle(
                    "Open in Preview after capture",
                    isOn: Binding(
                        get: { state.shouldOpenPreview },
                        set: { state.setShouldOpenPreview($0) }
                    )
                )
            }
        }
    }
}

struct InstallSection: View {
    @EnvironmentObject private var state: AppState
    @Binding var isDropTarget: Bool
    let dropTypes: [UTType]

    var body: some View {
        Section {
            Text("Install APK")
                .font(.title2)

            VStack(alignment: .leading, spacing: 12) {
                Text("Drag and drop an APK file or choose it manually.")
                    .foregroundColor(.secondary)

                DropTargetView(isTargeted: $isDropTarget, dropTypes: dropTypes) { url in
                    state.installAPK(from: url)
                }
                .frame(height: 160)

                Button("Choose APK…") {
                    if let url = chooseFile(allowedExtensions: ["apk"]) {
                        state.installAPK(from: url)
                    }
                }
            }
        }
    }
}

struct DropTargetView: View {
    @Binding var isTargeted: Bool
    let dropTypes: [UTType]
    let handler: (URL) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [10]))
                .foregroundColor(isTargeted ? .accentColor : .secondary)

            VStack(spacing: 8) {
                Image(systemName: "square.and.arrow.down")
                    .font(.largeTitle)
                Text("Drop APK here")
            }
            .foregroundColor(isTargeted ? .accentColor : .secondary)
        }
        .onDrop(of: dropTypes, isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            let identifier = UTType.fileURL.identifier
            provider.loadDataRepresentation(forTypeIdentifier: identifier) { data, _ in
                guard let data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }
                Task { @MainActor in
                    handler(url)
                }
            }
            return true
        }
    }
}

// MARK: - Preferences

struct PreferencesView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Preferences")
                .font(.title)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Android Platform Tools")
                        .font(.headline)

                    PathRow(
                        label: "Current path",
                        value: state.platformToolsPath?.abbreviatingWithTildeInPath() ?? "Not set"
                    )

                    HStack {
                        Button("Choose Folder…") {
                            if let path = chooseDirectory(initialPath: state.platformToolsPath) {
                                state.setPlatformToolsPath(path)
                            }
                        }
                        Button("Clear") {
                            state.clearPlatformToolsPath()
                        }
                        .disabled(state.platformToolsPath == nil)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Screenshots")
                        .font(.headline)

                    PathRow(
                        label: "Save to",
                        value: state.screenshotSavePath.abbreviatingWithTildeInPath()
                    )

                    Button("Choose Folder…") {
                        if let newPath = chooseDirectory(initialPath: state.screenshotSavePath) {
                            state.setScreenshotSavePath(newPath)
                        }
                    }

                    Toggle(
                        "Open in Preview after capture",
                        isOn: Binding(
                            get: { state.shouldOpenPreview },
                            set: { state.setShouldOpenPreview($0) }
                        )
                    )
                }
            }

            HStack {
                Spacer()
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 480)
    }
}

struct PathRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .bold()
            Text(value)
                .font(.body)
                .foregroundColor(value == "Not set" ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// MARK: - Helpers

func chooseDirectory(initialPath: String?) -> String? {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    if let initialPath {
        let expanded = NSString(string: initialPath).expandingTildeInPath
        panel.directoryURL = URL(fileURLWithPath: expanded)
    }

    return panel.runModal() == .OK ? panel.url?.path : nil
}

func chooseFile(allowedExtensions: [String]) -> URL? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    panel.allowedFileTypes = allowedExtensions
    return panel.runModal() == .OK ? panel.url : nil
}
