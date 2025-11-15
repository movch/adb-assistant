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

            // Prefer a direct file URL representation and copy it synchronously
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { tempURL, _ in
                    guard let tempURL else { return }
                    copyToStableTempAndInstall(from: tempURL)
                }
                return true
            }

            // Fallback: explicitly ask for APK file representation
            if let apk = UTType(filenameExtension: "apk"),
               provider.hasItemConformingToTypeIdentifier(apk.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: apk.identifier) { url, _ in
                    guard let url else { return }
                    copyToStableTempAndInstall(from: url)
                }
                return true
            }

            return false
        }
    }

    private func copyToStableTempAndInstall(from sourceURL: URL) {
        var didAccess = false
        if sourceURL.startAccessingSecurityScopedResource() {
            didAccess = true
        }
        defer {
            if didAccess {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let ext = sourceURL.pathExtension.isEmpty ? "apk" : sourceURL.pathExtension
        let destURL = tempDir.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)

        do {
            if fileManager.fileExists(atPath: destURL.path) {
                try? fileManager.removeItem(at: destURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destURL)
            Task { @MainActor in
                state.installAPK(from: destURL)
            }
        } catch {
            // If copy fails, attempt reading data and writing it ourselves
            do {
                let data = try Data(contentsOf: sourceURL)
                try data.write(to: destURL, options: [.atomic])
                Task { @MainActor in
                    state.installAPK(from: destURL)
                }
            } catch {
                // Give up silently if we cannot persist the file
            }
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

struct MemoryUsageTileView: View {
    @EnvironmentObject private var state: AppState
    @Binding var presentedSettings: TileID?

    private var latestValue: Double? {
        state.memoryHistory.last?.value
    }

    var body: some View {
        TileCard(
            iconName: nil,
            accentColor: .teal,
            title: "RAM Usage",
            subtitle: latestText,
            isEnabled: state.selectedDevice != nil,
            isActive: false,
            showsSettingsButton: false,
            onTap: { presentedSettings = .memoryUsage },
            onSettings: {},
            content: {
                MemoryGraphView(samples: state.memoryHistory)
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

struct MemoryGraphView: View {
    let samples: [MemoryPoint]

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
                            gradient: Gradient(colors: [.teal, .green]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )

                path
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.teal.opacity(0.3), .clear]),
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
        VStack(alignment: .leading, spacing: 12) {
            if iconName != nil || showsSettingsButton {
                HStack(alignment: .top, spacing: 12) {
                    if let iconName {
                        Image(systemName: iconName)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(accentColor)
                            .symbolRenderingMode(.hierarchical)
                    }
                    Spacer(minLength: 0)
                    if showsSettingsButton {
                        Button(action: { if isEnabled { onSettings() } }, label: {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.secondary)
                                .padding(6)
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
                .transition(.opacity)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(isEnabled ? .primary : .secondary)
                    .lineLimit(2)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Styles

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
            .frame(
                maxWidth: .infinity,
                minHeight: TileLayoutMetrics.tileMinHeight,
                alignment: .topLeading
            )
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
