import Foundation
import SwiftUI

enum CapabilityTileID {
    static let cpuUsage = "metrics.cpuUsage"
    static let memoryUsage = "metrics.memoryUsage"
    static let rebootSystem = "reboot.system"
    static let rebootRecovery = "reboot.recovery"
    static let rebootBootloader = "reboot.bootloader"
    static let screenshot = "screenshots.take"
    static let installApk = "install.apk"
}

struct CapabilitySectionConfig: Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let tiles: [String]
    let order: Int
}

struct CapabilityRenderContext {
    let state: AppState
    let deviceList: DeviceListViewModel
}

@MainActor
protocol CapabilityUIProvider {
    var section: CapabilitySectionConfig { get }

    func makeTileView(tileID: String, context: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView
    func makeSettingsView(tileID: String, state: AppState, presentedSettings: Binding<String?>) -> AnyView?
}
