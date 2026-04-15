import Foundation

@MainActor
final class DeviceListViewModel: ObservableObject {
    @Published private(set) var devices: [Device] = []
    @Published var selectedDeviceID: String?
    @Published private(set) var isRefreshing = false

    var selectedDevice: Device? {
        guard let selectedDeviceID else { return nil }
        return devices.first { $0.identifier == selectedDeviceID }
    }

    func beginRefresh() {
        isRefreshing = true
    }

    func finishRefresh(with newDevices: [Device]) {
        isRefreshing = false
        let previousSelection = selectedDeviceID
        devices = newDevices

        if let previousSelection,
           newDevices.contains(where: { $0.identifier == previousSelection }) {
            selectedDeviceID = previousSelection
        } else {
            selectedDeviceID = newDevices.first?.identifier
        }
    }

    func clear() {
        devices = []
        selectedDeviceID = nil
        isRefreshing = false
    }
}
