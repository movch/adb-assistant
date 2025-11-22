import AppKit
import Combine
import Foundation

enum TileSectionID: String, CaseIterable, Identifiable {
    case metrics
    case reboot
    case screenshots
    case install

    var id: String { rawValue }
}

enum TileID: String, CaseIterable, Identifiable {
    case cpuUsage
    case memoryUsage
    case rebootSystem
    case rebootRecovery
    case rebootBootloader
    case takeScreenshot
    case installApk

    var id: String { rawValue }
}

struct TileSectionConfig: Identifiable {
    let id: TileSectionID
    let title: String
    let subtitle: String?
    let tiles: [TileID]
}

struct CPUPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

struct MemoryPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

struct AppAlert: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
}

@MainActor
final class AppState: NSObject, ObservableObject {
    @Published private(set) var devices: [Device] = []
    @Published var selectedDeviceID: String? {
        didSet {
            if selectedDeviceID != oldValue {
                restartCPUMonitoring()
                restartMemoryMonitoring()
            }
        }
    }

    @Published private(set) var platformToolsPath: String?
    @Published private(set) var screenshotSavePath: String
    @Published private(set) var shouldOpenPreview: Bool
    @Published var alert: AppAlert?
    @Published private(set) var isRefreshing = false
    @Published var cpuUpdateInterval: TimeInterval = 1 {
        didSet {
            if cpuUpdateInterval <= 0 {
                cpuUpdateInterval = 1
            }
            restartCPUMonitoring()
            restartMemoryMonitoring()
        }
    }

    @Published private(set) var cpuHistory: [CPUPoint] = []
    @Published private(set) var memoryHistory: [MemoryPoint] = []

    @Published private(set) var sectionOrder: [TileSectionID] = [
        .metrics,
        .reboot,
        .screenshots,
        .install
    ]

    @Published private(set) var tileOrder: [TileSectionID: [TileID]] = [
        .metrics: [.cpuUsage, .memoryUsage],
        .reboot: [.rebootSystem, .rebootRecovery, .rebootBootloader],
        .screenshots: [.takeScreenshot],
        .install: [.installApk]
    ]

    private let shell: ShellType
    private let defaults: Defaults
    private var usbWatcher: USBWatcher?
    private var cpuMonitorTask: Task<Void, Never>?
    private var memoryMonitorTask: Task<Void, Never>?
    private let maxCPUSamples = 60
    private let maxMemorySamples = 60

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

    var tileSections: [TileSectionConfig] {
        sectionOrder.compactMap { sectionId in
            guard let tiles = tileOrder[sectionId], !tiles.isEmpty else { return nil }
            switch sectionId {
            case .metrics:
                let subtitle = selectedDevice.map { $0.model.isEmpty ? $0.identifier : $0.model }
                return TileSectionConfig(
                    id: sectionId,
                    title: "Device Metrics",
                    subtitle: subtitle,
                    tiles: tiles
                )
            case .reboot:
                return TileSectionConfig(
                    id: sectionId,
                    title: "Reboot",
                    subtitle: "Restart the connected device",
                    tiles: tiles
                )
            case .screenshots:
                return TileSectionConfig(
                    id: sectionId,
                    title: "Screenshots",
                    subtitle: "Capture and manage screenshots",
                    tiles: tiles
                )
            case .install:
                return TileSectionConfig(
                    id: sectionId,
                    title: "Install APK",
                    subtitle: "Deploy packages to the device",
                    tiles: tiles
                )
            }
        }
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
        stopCPUMonitoring()
        stopMemoryMonitoring()
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

    func restartCPUMonitoring() {
        cpuMonitorTask?.cancel()
        cpuMonitorTask = nil
        cpuHistory = []

        guard let identifier = selectedDevice?.identifier else { return }

        cpuMonitorTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                guard let wrapper = makeWrapper() else { return }

                let load = await Task.detached(priority: .utility) { () -> Double in
                    wrapper.fetchCPULoad(identifier: identifier) ?? 0
                }.value

                await MainActor.run {
                    self.appendCPUSample(load)
                }

                try? await Task.sleep(nanoseconds: UInt64(cpuUpdateInterval * 1_000_000_000))
            }
        }
    }

    func stopCPUMonitoring() {
        cpuMonitorTask?.cancel()
        cpuMonitorTask = nil
        cpuHistory = []
    }

    func restartMemoryMonitoring() {
        memoryMonitorTask?.cancel()
        memoryMonitorTask = nil
        memoryHistory = []

        guard let identifier = selectedDevice?.identifier else { return }

        memoryMonitorTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                guard let wrapper = makeWrapper() else { return }

                let usage = await Task.detached(priority: .utility) { () -> Double? in
                    wrapper.fetchMemoryUsage(identifier: identifier)
                }.value

                await MainActor.run {
                    self.appendMemorySample(usage ?? 0)
                }

                try? await Task.sleep(nanoseconds: UInt64(cpuUpdateInterval * 1_000_000_000))
            }
        }
    }

    func stopMemoryMonitoring() {
        memoryMonitorTask?.cancel()
        memoryMonitorTask = nil
        memoryHistory = []
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

    func appendCPUSample(_ value: Double) {
        cpuHistory.append(CPUPoint(timestamp: Date(), value: value))
        if cpuHistory.count > maxCPUSamples {
            cpuHistory.removeFirst(cpuHistory.count - maxCPUSamples)
        }
    }

    func appendMemorySample(_ value: Double) {
        memoryHistory.append(MemoryPoint(timestamp: Date(), value: value))
        if memoryHistory.count > maxMemorySamples {
            memoryHistory.removeFirst(memoryHistory.count - maxMemorySamples)
        }
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
