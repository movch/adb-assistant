import SwiftUI
import UniformTypeIdentifiers

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

struct DragDropTileView: View {
    @EnvironmentObject private var state: AppState
    @Binding var presentedSettings: TileID?
    @State private var isTargeted = false

    private var dropTypes: [UTType] {
        if let apk = UTType(filenameExtension: "apk") {
            return [apk, .fileURL]
        }
        return [.fileURL]
    }

    var body: some View {
        TileCard(
            iconName: nil,
            accentColor: .blue,
            title: "Install APK",
            subtitle: "Drop file or tap to choose",
            isEnabled: state.selectedDevice != nil,
            isActive: isTargeted,
            showsSettingsButton: false,
            onTap: presentFilePicker,
            onSettings: { presentedSettings = .installApk },
            content: {
                HStack {
                    Spacer()
                    VStack(spacing: 6) {
                        Spacer()
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(isTargeted ? .blue : .secondary)
                        Text("Drop APK here")
                            .font(.footnote)
                            .foregroundColor(isTargeted ? .blue : .secondary)
                        Spacer()
                    }
                    Spacer()
                }
            }
        )
        .onDrop(of: dropTypes, isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }
            let identifier = UTType.fileURL.identifier
            provider.loadDataRepresentation(forTypeIdentifier: identifier) { data, _ in
                guard let data,
                      let url = URL(dataRepresentation: data, relativeTo: nil)
                else { return }
                Task { @MainActor in
                    state.installAPK(from: url)
                }
            }
            return true
        }
    }

    private func presentFilePicker() {
        guard let url = chooseFile(allowedExtensions: ["apk"]) else { return }
        state.installAPK(from: url)
    }
}

struct CPULoadTileView: View {
    @EnvironmentObject private var state: AppState
    @Binding var presentedSettings: TileID?

    private var latestValue: Double? {
        state.cpuHistory.last?.value
    }

    var body: some View {
        TileCard(
            iconName: nil,
            accentColor: .purple,
            title: "CPU Usage",
            subtitle: latestText,
            isEnabled: state.selectedDevice != nil,
            isActive: false,
            showsSettingsButton: false,
            onTap: { presentedSettings = .cpuUsage },
            onSettings: {},
            content: {
                CPUGraphView(samples: state.cpuHistory)
                    .frame(height: 80)
            }
        )
    }

    private var latestText: String? {
        guard let value = latestValue else { return "Awaiting data…" }
        return String(format: "%.1f%% · every %.1fs", value, state.cpuUpdateInterval)
    }
}

struct CPUGraphView: View {
    let samples: [CPUPoint]

    private let maxPoints = 60

    var body: some View {
        GeometryReader { geo in
            let values = Array(samples.suffix(maxPoints).map(\.value))
            if values.isEmpty {
                Text("No samples")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let maxValue = max(values.max() ?? 0, 100)
                let minValue = 0.0
                let stepX = values.count > 1 ? geo.size.width / CGFloat(values.count - 1) : 0

                let path = Path { path in
                    for (index, value) in values.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalized = (value - minValue) / (maxValue - minValue)
                        let y = geo.size.height - (CGFloat(normalized) * geo.size.height)
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }

                path
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple, .pink]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                path
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.purple.opacity(0.3), .clear]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(0.3)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.15))
        )
    }
}

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
        if isActive {
            return Color.accentColor.opacity(0.18)
        }
        return Color(NSColor.controlBackgroundColor).opacity(0.9)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: TileLayoutMetrics.tileCornerRadius)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: TileLayoutMetrics.tileCornerRadius)
                        .stroke(Color.black.opacity(0.05))
                )
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 12) {
                if iconName != nil || showsSettingsButton {
                    HStack(alignment: .top) {
                        if let iconName {
                            Image(systemName: iconName)
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        Spacer()
                        if showsSettingsButton {
                            Button(
                                action: {
                                    if isEnabled { onSettings() }
                                },
                                label: {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.secondary)
                                        .padding(6)
                                        .background(
                                            Circle()
                                                .fill(Color.secondary.opacity(0.12))
                                        )
                                }
                            )
                            .buttonStyle(.plain)
                            .disabled(!isEnabled)
                        }
                    }
                }
                
                content()

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isEnabled ? .primary : .secondary)
                        .lineLimit(2)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding(TileLayoutMetrics.tileInnerPadding)
        }
        .frame(width: TileLayoutMetrics.tileSize.width, height: TileLayoutMetrics.tileSize.height)
        .opacity(isEnabled ? 1 : 0.55)
        .contentShape(RoundedRectangle(cornerRadius: TileLayoutMetrics.tileCornerRadius))
        .onTapGesture {
            if isEnabled { onTap() }
        }
    }
}
