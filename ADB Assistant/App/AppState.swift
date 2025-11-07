import AppKit
import Combine
import Foundation

struct AppAlert: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class AppState: NSObject, ObservableObject {
    @Published private(set) var devices: [Device] = []
    @Published var selectedDeviceID: String?
    @Published private(set) var platformToolsPath: String?
    @Published private(set) var screenshotSavePath: String
    @Published private(set) var shouldOpenPreview: Bool
    @Published var alert: AppAlert?
    @Published private(set) var isRefreshing = false

    private let shell: ShellType
    private let defaults: Defaults
    private var usbWatcher: USBWatcher?

    init(shell: ShellType, defaults: Defaults) {
        self.shell = shell
        self.defaults = defaults

        platformToolsPath = defaults.string(forKey: .platformToolsPath)
        screenshotSavePath = defaults.string(forKey: .screenshotsSavePath) ?? "~/Desktop"
        shouldOpenPreview = defaults.bool(forKey: .screenshotsShouldOpenPreview) ?? true

        super.init()

        if platformToolsPath != nil {
            configureUSBWatcher()
            refreshDevices()
        }
    }

    var selectedDevice: Device? {
        guard let id = selectedDeviceID else { return nil }
        return devices.first { $0.identifier == id }
    }

    func refreshDevices() {
        guard let wrapper = makeWrapper() else {
            devices = []
            selectedDeviceID = nil
            return
        }

        isRefreshing = true

        Task.detached(priority: .userInitiated) { [weak self] in
            let ids = wrapper.listDeviceIds()
            let fetchedDevices = ids.map { wrapper.getDevice(forId: $0) }

            await MainActor.run { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.isRefreshing = false
                strongSelf.updateDevices(fetchedDevices)
            }
        }
    }

    func setPlatformToolsPath(_ path: String) {
        guard validateADB(at: path) else {
            alert = AppAlert(title: "ADB Not Found", message: "The selected folder does not contain an adb executable. Please choose the Platform Tools directory.")
            return
        }

        platformToolsPath = path
        defaults.setString(path, forKey: .platformToolsPath)
        configureUSBWatcher()
        refreshDevices()
    }

    func clearPlatformToolsPath() {
        platformToolsPath = nil
        defaults.removeValue(forKey: .platformToolsPath)
        usbWatcher = nil
        devices = []
        selectedDeviceID = nil
    }

    func setScreenshotSavePath(_ path: String) {
        screenshotSavePath = path
        defaults.setString(path, forKey: .screenshotsSavePath)
    }

    func setShouldOpenPreview(_ flag: Bool) {
        shouldOpenPreview = flag
        defaults.setBool(flag, forKey: .screenshotsShouldOpenPreview)
    }

    func rebootSelectedDevice(to type: ADBRebootType) {
        guard let device = selectedDevice else {
            alert = AppAlert(title: "No Device Selected", message: "Select a device to reboot.")
            return
        }
        guard let wrapper = makeWrapper() else {
            alert = AppAlert(title: "Missing Platform Tools", message: "Set the Platform Tools path before issuing ADB commands.")
            return
        }

        Task.detached(priority: .userInitiated) {
            wrapper.reboot(to: type, identifier: device.identifier)
        }
    }

    func takeScreenshot() {
        guard let device = selectedDevice else {
            alert = AppAlert(title: "No Device Selected", message: "Select a device before capturing a screenshot.")
            return
        }
        guard let wrapper = makeWrapper() else {
            alert = AppAlert(title: "Missing Platform Tools", message: "Set the Platform Tools path before issuing ADB commands.")
            return
        }

        let modelName = device.model.isEmpty ? device.identifier : device.model
        let filename = "\(modelName.toFilenameString())-\(Date().toFilenameString()).png"
        let tempDevicePath = "/sdcard/\(filename)"
        let expandedSavePath = NSString(string: screenshotSavePath).expandingTildeInPath
        let openPreview = shouldOpenPreview

        Task.detached(priority: .userInitiated) {
            wrapper.takeScreenshot(identifier: device.identifier, path: tempDevicePath)
            wrapper.pull(identifier: device.identifier, fromPath: tempDevicePath, toPath: expandedSavePath)
            wrapper.remove(identifier: device.identifier, path: tempDevicePath)

            if openPreview {
                let localPath = URL(fileURLWithPath: expandedSavePath).appendingPathComponent(filename)
                DispatchQueue.main.async {
                    NSWorkspace.shared.open(localPath)
                }
            }
        }
    }

    func installAPK(from url: URL) {
        guard let device = selectedDevice else {
            alert = AppAlert(title: "No Device Selected", message: "Select a device before installing an APK.")
            return
        }
        guard let wrapper = makeWrapper() else {
            alert = AppAlert(title: "Missing Platform Tools", message: "Set the Platform Tools path before issuing ADB commands.")
            return
        }
        guard url.pathExtension.lowercased() == "apk" else {
            alert = AppAlert(title: "Unsupported File", message: "Please choose an APK file.")
            return
        }

        Task.detached(priority: .userInitiated) {
            wrapper.installAPK(identifier: device.identifier, fromPath: url.path)
        }
    }
}

// MARK: - USBWatcherDelegate

@MainActor extension AppState: USBWatcherDelegate {
    func deviceAdded(_: io_object_t) {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            self?.refreshDevices()
        }
    }

    func deviceRemoved(_: io_object_t) {
        Task { @MainActor [weak self] in
            self?.refreshDevices()
        }
    }
}

// MARK: - Private helpers

private extension AppState {
    func makeWrapper() -> ADBWrapperType? {
        guard let path = platformToolsPath, !path.isEmpty else { return nil }
        return ADBWrapper(shell: shell, platformToolsPath: path)
    }

    func configureUSBWatcher() {
        usbWatcher = USBWatcher(delegate: self)
    }

    func updateDevices(_ newDevices: [Device]) {
        let previouslySelected = selectedDeviceID
        devices = newDevices

        if let previous = previouslySelected, newDevices.contains(where: { $0.identifier == previous }) {
            selectedDeviceID = previous
        } else {
            selectedDeviceID = newDevices.first?.identifier
        }
    }

    func validateADB(at path: String) -> Bool {
        let adbPath = URL(fileURLWithPath: path).appendingPathComponent("adb").path
        return FileManager.default.fileExists(atPath: adbPath)
    }
}
