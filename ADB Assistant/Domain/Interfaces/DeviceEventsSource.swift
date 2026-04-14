import Foundation

protocol DeviceEventsSource: AnyObject {
    var onDevicesChanged: (() -> Void)? { get set }
}

protocol DeviceEventsSourceFactory {
    func makeSource() -> DeviceEventsSource
}
