import Foundation

@MainActor
final class MetricsViewModel: ObservableObject {
    @Published private(set) var cpuHistory: [CPUPoint] = []
    @Published private(set) var memoryHistory: [MemoryPoint] = []

    private let maxCPUSamples = 60
    private let maxMemorySamples = 60

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

    func clearCPU() {
        cpuHistory = []
    }

    func clearMemory() {
        memoryHistory = []
    }
}
