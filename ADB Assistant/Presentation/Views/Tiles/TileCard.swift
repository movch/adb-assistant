import SwiftUI

struct TileCard<Content: View>: View {
    let iconName: String?
    let accentColor: Color
    let title: String
    let subtitle: String?
    let isEnabled: Bool
    let isActive: Bool
    let showsSettingsButton: Bool
    let onTap: () -> Void
    let onSettings: () -> Void
    @ViewBuilder let content: () -> Content

    init(
        iconName: String?,
        accentColor: Color,
        title: String,
        subtitle: String?,
        isEnabled: Bool,
        isActive: Bool,
        showsSettingsButton: Bool = true,
        onTap: @escaping () -> Void,
        onSettings: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.iconName = iconName
        self.accentColor = accentColor
        self.title = title
        self.subtitle = subtitle
        self.isEnabled = isEnabled
        self.isActive = isActive
        self.showsSettingsButton = showsSettingsButton
        self.onTap = onTap
        self.onSettings = onSettings
        self.content = content
    }

    private var backgroundColor: Color {
        isActive
            ? Color.accentColor.opacity(0.22)
            : Color(NSColor.controlBackgroundColor).opacity(0.94)
    }

    var body: some View {
        Button {
            if isEnabled {
                onTap()
            }
        } label: {
            cardContent
        }
        .buttonStyle(
            PressableTileButtonStyle(
                cornerRadius: TileLayoutMetrics.tileCornerRadius,
                baseColor: backgroundColor,
                pressedOverlay: Color.accentColor.opacity(0.18),
                borderColor: Color.black.opacity(0.05),
                shadowColor: Color.black.opacity(0.2),
                isEnabled: isEnabled
            )
        )
        .disabled(!isEnabled)
    }

    @ViewBuilder
    private var cardContent: some View {
        GeometryReader { _ in
            VStack(alignment: .leading, spacing: 6) {
                if iconName != nil || showsSettingsButton {
                    HStack(alignment: .top, spacing: 8) {
                        if let iconName {
                            Image(systemName: iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(accentColor)
                                .symbolRenderingMode(.hierarchical)
                        }
                        Spacer(minLength: 0)
                        if showsSettingsButton {
                            Button(action: { if isEnabled { onSettings() } }, label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(4)
                                    .background(
                                        Circle()
                                            .fill(Color.secondary.opacity(0.12))
                                    )
                            })
                            .buttonStyle(.plain)
                            .disabled(!isEnabled)
                            .accessibilityLabel(Text("Open tile settings"))
                        }
                    }
                }

                content()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 35)
                    .clipped()
                    .transition(.opacity)

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isEnabled ? .primary : .secondary)
                        .lineLimit(1)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct PressableTileButtonStyle: ButtonStyle {
    let cornerRadius: CGFloat
    let baseColor: Color
    let pressedOverlay: Color
    let borderColor: Color
    let shadowColor: Color
    let isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed && isEnabled

        return configuration.label
            .padding(TileLayoutMetrics.tileContentPadding)
            .frame(width: TileLayoutMetrics.tileSize, height: TileLayoutMetrics.tileSize, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(baseColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(pressedOverlay)
                            .opacity(isPressed ? 1 : 0)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(borderColor)
                    )
            )
            .scaleEffect(isPressed ? 0.97 : 1)
            .shadow(
                color: shadowColor.opacity(isPressed ? 0.12 : 0.18),
                radius: isPressed ? 6 : 12,
                x: 0,
                y: isPressed ? 3 : 8
            )
            .opacity(isEnabled ? 1 : 0.55)
            .animation(.spring(response: 0.28, dampingFraction: 0.7, blendDuration: 0.1), value: isPressed)
    }
}
