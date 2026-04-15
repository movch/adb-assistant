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
    private let deviceEventsCoordinator: DeviceEventsCoordinator
    let dashboardViewModel: DashboardViewModel
    let deviceListViewModel: DeviceListViewModel
    let metricsViewModel: MetricsViewModel
    private let refreshDevicesUseCase: RefreshDevicesUseCase
    private let deviceActionsService: DeviceActionsService
    private let deviceMetricsCoordinator: DeviceMetricsCoordinator

    init(
        gatewayFactory: DeviceGatewayFactory,
        preferences: PreferencesStore,
        eventsSourceFactory: DeviceEventsSourceFactory
    ) {
        self.preferences = preferences
        deviceEventsCoordinator = DeviceEventsCoordinator(eventsSourceFactory: eventsSourceFactory)
        dashboardViewModel = DashboardViewModel()
        deviceListViewModel = DeviceListViewModel()
        metricsViewModel = MetricsViewModel()
        refreshDevicesUseCase = RefreshDevicesUseCase(gatewayFactory: gatewayFactory)
        let rebootDeviceUseCase = RebootDeviceUseCase(gatewayFactory: gatewayFactory)
        let takeScreenshotUseCase = TakeScreenshotUseCase(gatewayFactory: gatewayFactory)
        let installAPKUseCase = InstallAPKUseCase(gatewayFactory: gatewayFactory)
        deviceActionsService = DeviceActionsService(
            rebootDeviceUseCase: rebootDeviceUseCase,
            takeScreenshotUseCase: takeScreenshotUseCase,
            installAPKUseCase: installAPKUseCase
        )
        let fetchDeviceMetricsUseCase = FetchDeviceMetricsUseCase(gatewayFactory: gatewayFactory)
        deviceMetricsCoordinator = DeviceMetricsCoordinator(
            fetchDeviceMetricsUseCase: fetchDeviceMetricsUseCase,
            metricsViewModel: metricsViewModel
        )

        platformToolsPath = preferences.string(forKey: .platformToolsPath)
        screenshotSavePath = preferences.string(forKey: .screenshotsSavePath) ?? "~/Desktop"
        shouldOpenPreview = preferences.bool(forKey: .screenshotsShouldOpenPreview) ?? true

        if platformToolsPath != nil {
            startDeviceWatcher()
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
        startDeviceWatcher()
        refreshDevices()
    }

    func clearPlatformToolsPath() {
        platformToolsPath = nil
        preferences.removeValue(forKey: .platformToolsPath)
        deviceEventsCoordinator.stopWatching()
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
        let platformToolsPath = platformToolsPath

        Task {
            await deviceActionsService.reboot(platformToolsPath: platformToolsPath, deviceID: device.identifier, type: type)
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
        let platformToolsPath = platformToolsPath
        let screenshotSavePath = screenshotSavePath
        let shouldOpenPreview = shouldOpenPreview

        Task {
            await deviceActionsService.takeScreenshot(
                platformToolsPath: platformToolsPath,
                device: device,
                screenshotSavePath: screenshotSavePath,
                shouldOpenPreview: shouldOpenPreview
            )
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
        let platformToolsPath = platformToolsPath

        Task {
            await deviceActionsService.installAPK(platformToolsPath: platformToolsPath, deviceID: device.identifier, apkURL: url)
        }
    }

    func restartCPUMonitoring() {
        let identifier = selectedDevice?.identifier
        let path = hasConfiguredPlatformTools ? platformToolsPath : nil
        deviceMetricsCoordinator.restartCPUMonitoring(deviceID: identifier, platformToolsPath: path, interval: cpuUpdateInterval)
    }

    func stopCPUMonitoring() {
        deviceMetricsCoordinator.stopCPUMonitoring()
    }

    func restartMemoryMonitoring() {
        let identifier = selectedDevice?.identifier
        let path = hasConfiguredPlatformTools ? platformToolsPath : nil
        deviceMetricsCoordinator.restartMemoryMonitoring(deviceID: identifier, platformToolsPath: path, interval: cpuUpdateInterval)
    }

    func stopMemoryMonitoring() {
        deviceMetricsCoordinator.stopMemoryMonitoring()
    }
}

private extension AppState {
    var hasConfiguredPlatformTools: Bool {
        guard let path = platformToolsPath else { return false }
        return !path.isEmpty
    }

    func startDeviceWatcher() {
        deviceEventsCoordinator.startWatching { [weak self] in
            self?.refreshDevices()
        }
    }

    func validateADB(at path: String) -> Bool {
        let adbPath = URL(fileURLWithPath: path).appendingPathComponent("adb").path
        return FileManager.default.fileExists(atPath: adbPath)
    }
}
