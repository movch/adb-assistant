import Foundation
import SwiftUI

@MainActor
final class CapabilityRegistry: ObservableObject {
    private var providersByTileID: [String: CapabilityUIProvider] = [:]
    private(set) var sections: [CapabilitySectionConfig] = []

    init(providers: [CapabilityUIProvider]) {
        sections = providers
            .map(\.section)
            .sorted { $0.order < $1.order }

        for provider in providers {
            for tile in provider.section.tiles {
                providersByTileID[tile] = provider
            }
        }
    }

    static func makeDefault() -> CapabilityRegistry {
        CapabilityRegistry(
            providers: [
                MetricsCapabilityProvider(),
                RebootCapabilityProvider(),
                ScreenshotCapabilityProvider(),
                InstallCapabilityProvider()
            ]
        )
    }

    func makeTileView(tileID: String, context: CapabilityRenderContext, presentedSettings: Binding<String?>) -> AnyView {
        providersByTileID[tileID]?.makeTileView(tileID: tileID, context: context, presentedSettings: presentedSettings)
            ?? AnyView(EmptyView())
    }

    func makeSettingsView(tileID: String, state: AppState, presentedSettings: Binding<String?>) -> AnyView {
        providersByTileID[tileID]?.makeSettingsView(tileID: tileID, state: state, presentedSettings: presentedSettings)
            ?? AnyView(
                PlaceholderSettingsView(
                    title: "Tile Settings",
                    message: "No settings available for this tile.",
                    onClose: { presentedSettings.wrappedValue = nil }
                )
            )
    }
}
