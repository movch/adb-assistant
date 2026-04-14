import Foundation

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
