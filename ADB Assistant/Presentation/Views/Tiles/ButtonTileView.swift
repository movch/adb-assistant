import SwiftUI

struct ButtonTileView: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isEnabled: Bool
    let action: () -> Void
    let onSettings: () -> Void

    var body: some View {
        TileCard(
            iconName: icon,
            accentColor: .accentColor,
            title: title,
            subtitle: subtitle,
            isEnabled: isEnabled,
            isActive: false,
            onTap: action,
            onSettings: onSettings,
            content: {
                EmptyView()
            }
        )
    }
}
