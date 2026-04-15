import AppKit
import Foundation

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var platformToolsPath: String?
    @Published private(set) var screenshotSavePath: String
    @Published private(set) var shouldOpenPreview: Bool
    @Published var alert: AppAlert?
    @Published var cpuUpdateInterval: TimeInterval = 1 {
        didSet {
            if cpuUpdateInterval <= 0 {
                cpuUpdateInterval = 1
            }
            restartCPUMonitoring()
            restartMemoryMonitoring()
        }
    }

    private let preferences: PreferencesStore
    private let eventsSourceFactory: DeviceEventsSourceFactory
    let dashboardViewModel: DashboardViewModel
    let deviceListViewModel: DeviceListViewModel
    let metricsViewModel: MetricsViewModel
    private let refreshDevicesUseCase: RefreshDevicesUseCase
    private let rebootDeviceUseCase: RebootDeviceUseCase
    private let takeScreenshotUseCase: TakeScreenshotUseCase
    private let installAPKUseCase: InstallAPKUseCase
    private let fetchDeviceMetricsUseCase: FetchDeviceMetricsUseCase
    private var deviceEventsSource: DeviceEventsSource?
    private var cpuMonitorTask: Task<Void, Never>?
    private var memoryMonitorTask: Task<Void, Never>?

    init(
        gatewayFactory: DeviceGatewayFactory,
        preferences: PreferencesStore,
        eventsSourceFactory: DeviceEventsSourceFactory
    ) {
        self.preferences = preferences
        self.eventsSourceFactory = eventsSourceFactory
        dashboardViewModel = DashboardViewModel()
        deviceListViewModel = DeviceListViewModel()
        metricsViewModel = MetricsViewModel()
        refreshDevicesUseCase = RefreshDevicesUseCase(gatewayFactory: gatewayFactory)
        rebootDeviceUseCase = RebootDeviceUseCase(gatewayFactory: gatewayFactory)
        takeScreenshotUseCase = TakeScreenshotUseCase(gatewayFactory: gatewayFactory)
        installAPKUseCase = InstallAPKUseCase(gatewayFactory: gatewayFactory)
        fetchDeviceMetricsUseCase = FetchDeviceMetricsUseCase(gatewayFactory: gatewayFactory)

        platformToolsPath = preferences.string(forKey: .platformToolsPath)
        screenshotSavePath = preferences.string(forKey: .screenshotsSavePath) ?? "~/Desktop"
        shouldOpenPreview = preferences.bool(forKey: .screenshotsShouldOpenPreview) ?? true

        if platformToolsPath != nil {
            configureUSBWatcher()
            refreshDevices()
        }
    }

    var selectedDevice: Device? {
        deviceListViewModel.selectedDevice
    }

    func selectDevice(with identifier: String?) {
        guard deviceListViewModel.selectedDeviceID != identifier else { return }
        deviceListViewModel.selectedDeviceID = identifier
        restartCPUMonitoring()
        restartMemoryMonitoring()
    }

    func refreshDevices() {
        guard hasConfiguredPlatformTools else {
            deviceListViewModel.clear()
            return
        }

        deviceListViewModel.beginRefresh()
        let useCase = refreshDevicesUseCase
        let platformToolsPath = platformToolsPath

        Task.detached(priority: .userInitiated) { [weak self] in
            let fetchedDevices = useCase.execute(platformToolsPath: platformToolsPath)

            await MainActor.run { [weak self] in
                guard let self else { return }
                let previousSelection = deviceListViewModel.selectedDeviceID
                deviceListViewModel.finishRefresh(with: fetchedDevices)
                if deviceListViewModel.selectedDeviceID != previousSelection {
                    restartCPUMonitoring()
                    restartMemoryMonitoring()
                }
            }
        }
    }

    func setPlatformToolsPath(_ path: String) {
        guard validateADB(at: path) else {
            alert = AppAlert(title: "ADB Not Found", message: "The selected folder does not contain an adb executable. Please choose the Platform Tools directory.")
            return
        }

        platformToolsPath = path
        preferences.setString(path, forKey: .platformToolsPath)
        configureUSBWatcher()
        refreshDevices()
    }

    func clearPlatformToolsPath() {
        platformToolsPath = nil
        preferences.removeValue(forKey: .platformToolsPath)
        deviceEventsSource = nil
        deviceListViewModel.clear()
        stopCPUMonitoring()
        stopMemoryMonitoring()
    }

    func setScreenshotSavePath(_ path: String) {
        screenshotSavePath = path
        preferences.setString(path, forKey: .screenshotsSavePath)
    }

    func setShouldOpenPreview(_ flag: Bool) {
        shouldOpenPreview = flag
        preferences.setBool(flag, forKey: .screenshotsShouldOpenPreview)
    }

    func rebootSelectedDevice(to type: RebootType) {
        guard let device = selectedDevice else {
            alert = AppAlert(title: "No Device Selected", message: "Select a device to reboot.")
            return
        }
        guard hasConfiguredPlatformTools else {
            alert = AppAlert(title: "Missing Platform Tools", message: "Set the Platform Tools path before issuing ADB commands.")
            return
        }
        let useCase = rebootDeviceUseCase
        let platformToolsPath = platformToolsPath

        Task.detached(priority: .userInitiated) {
            _ = useCase.execute(platformToolsPath: platformToolsPath, deviceID: device.identifier, type: type)
        }
    }

    func takeScreenshot() {
        guard let device = selectedDevice else {
            alert = AppAlert(title: "No Device Selected", message: "Select a device before capturing a screenshot.")
            return
        }
        guard hasConfiguredPlatformTools else {
            alert = AppAlert(title: "Missing Platform Tools", message: "Set the Platform Tools path before issuing ADB commands.")
            return
        }
        let useCase = takeScreenshotUseCase
        let platformToolsPath = platformToolsPath
        let screenshotSavePath = screenshotSavePath
        let shouldOpenPreview = shouldOpenPreview

        Task.detached(priority: .userInitiated) {
            let request = ScreenshotRequest(device: device, savePath: screenshotSavePath, openPreview: shouldOpenPreview)
            if let result = useCase.execute(platformToolsPath: platformToolsPath, request: request),
               result.shouldOpenPreview {
                DispatchQueue.main.async {
                    NSWorkspace.shared.open(result.localFileURL)
                }
            }
        }
    }

    func installAPK(from url: URL) {
        guard let device = selectedDevice else {
            alert = AppAlert(title: "No Device Selected", message: "Select a device before installing an APK.")
            return
        }
        guard hasConfiguredPlatformTools else {
            alert = AppAlert(title: "Missing Platform Tools", message: "Set the Platform Tools path before issuing ADB commands.")
            return
        }
        guard url.pathExtension.lowercased() == "apk" else {
            alert = AppAlert(title: "Unsupported File", message: "Please choose an APK file.")
            return
        }
        let useCase = installAPKUseCase
        let platformToolsPath = platformToolsPath

        Task.detached(priority: .userInitiated) {
            _ = useCase.execute(platformToolsPath: platformToolsPath, deviceID: device.identifier, apkURL: url)
        }
    }

    func restartCPUMonitoring() {
        cpuMonitorTask?.cancel()
        cpuMonitorTask = nil
        metricsViewModel.clearCPU()

        guard let identifier = selectedDevice?.identifier else { return }

        cpuMonitorTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                guard hasConfiguredPlatformTools else { return }
                let useCase = fetchDeviceMetricsUseCase
                let platformToolsPath = platformToolsPath

                let load = await Task.detached(priority: .utility) { () -> Double in
                    useCase.fetchCPU(platformToolsPath: platformToolsPath, deviceID: identifier) ?? 0
                }.value

                await MainActor.run {
                    self.metricsViewModel.appendCPUSample(load)
                }

                try? await Task.sleep(nanoseconds: UInt64(cpuUpdateInterval * 1_000_000_000))
            }
        }
    }

    func stopCPUMonitoring() {
        cpuMonitorTask?.cancel()
        cpuMonitorTask = nil
        metricsViewModel.clearCPU()
    }

    func restartMemoryMonitoring() {
        memoryMonitorTask?.cancel()
        memoryMonitorTask = nil
        metricsViewModel.clearMemory()

        guard let identifier = selectedDevice?.identifier else { return }

        memoryMonitorTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }

            while !Task.isCancelled {
                guard hasConfiguredPlatformTools else { return }
                let useCase = fetchDeviceMetricsUseCase
                let platformToolsPath = platformToolsPath

                let usage = await Task.detached(priority: .utility) { () -> Double? in
                    useCase.fetchMemory(platformToolsPath: platformToolsPath, deviceID: identifier)
                }.value

                await MainActor.run {
                    self.metricsViewModel.appendMemorySample(usage ?? 0)
                }

                try? await Task.sleep(nanoseconds: UInt64(cpuUpdateInterval * 1_000_000_000))
            }
        }
    }

    func stopMemoryMonitoring() {
        memoryMonitorTask?.cancel()
        memoryMonitorTask = nil
        metricsViewModel.clearMemory()
    }
}

private extension AppState {
    var hasConfiguredPlatformTools: Bool {
        guard let path = platformToolsPath else { return false }
        return !path.isEmpty
    }

    func configureUSBWatcher() {
        let source = eventsSourceFactory.makeSource()
        source.onDevicesChanged = { [weak self] in
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                self?.refreshDevices()
            }
        }
        deviceEventsSource = source
    }

    func validateADB(at path: String) -> Bool {
        let adbPath = URL(fileURLWithPath: path).appendingPathComponent("adb").path
        return FileManager.default.fileExists(atPath: adbPath)
    }
}
