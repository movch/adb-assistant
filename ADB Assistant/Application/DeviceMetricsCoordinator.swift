import Foundation

@MainActor
final class DeviceMetricsCoordinator {
    private let fetchDeviceMetricsUseCase: FetchDeviceMetricsUseCase
    private let metricsViewModel: MetricsViewModel
    private var cpuMonitorTask: Task<Void, Never>?
    private var memoryMonitorTask: Task<Void, Never>?

    init(fetchDeviceMetricsUseCase: FetchDeviceMetricsUseCase, metricsViewModel: MetricsViewModel) {
        self.fetchDeviceMetricsUseCase = fetchDeviceMetricsUseCase
        self.metricsViewModel = metricsViewModel
    }

    func restartCPUMonitoring(deviceID: String?, platformToolsPath: String?, interval: TimeInterval) {
        cpuMonitorTask?.cancel()
        cpuMonitorTask = nil
        metricsViewModel.clearCPU()

        guard let deviceID else { return }
        let pollingInterval = max(1, interval)
        let useCase = fetchDeviceMetricsUseCase

        cpuMonitorTask = Task(priority: .utility) {
            while !Task.isCancelled {
                let load = await Task.detached(priority: .utility) { () -> Double in
                    useCase.fetchCPU(platformToolsPath: platformToolsPath, deviceID: deviceID) ?? 0
                }.value

                await MainActor.run {
                    self.metricsViewModel.appendCPUSample(load)
                }

                try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
            }
        }
    }

    func stopCPUMonitoring() {
        cpuMonitorTask?.cancel()
        cpuMonitorTask = nil
        metricsViewModel.clearCPU()
    }

    func restartMemoryMonitoring(deviceID: String?, platformToolsPath: String?, interval: TimeInterval) {
        memoryMonitorTask?.cancel()
        memoryMonitorTask = nil
        metricsViewModel.clearMemory()

        guard let deviceID else { return }
        let pollingInterval = max(1, interval)
        let useCase = fetchDeviceMetricsUseCase

        memoryMonitorTask = Task(priority: .utility) {
            while !Task.isCancelled {
                let usage = await Task.detached(priority: .utility) { () -> Double? in
                    useCase.fetchMemory(platformToolsPath: platformToolsPath, deviceID: deviceID)
                }.value

                await MainActor.run {
                    self.metricsViewModel.appendMemorySample(usage ?? 0)
                }

                try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
            }
        }
    }

    func stopMemoryMonitoring() {
        memoryMonitorTask?.cancel()
        memoryMonitorTask = nil
        metricsViewModel.clearMemory()
    }
}
