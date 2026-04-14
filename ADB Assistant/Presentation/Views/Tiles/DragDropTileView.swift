import SwiftUI
import UniformTypeIdentifiers

struct DragDropTileView: View {
    @EnvironmentObject private var state: AppState
    @EnvironmentObject private var deviceList: DeviceListViewModel
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
            isEnabled: deviceList.selectedDevice != nil,
            isActive: isTargeted,
            showsSettingsButton: false,
            onTap: presentFilePicker,
            onSettings: { presentedSettings = .installApk },
            content: {
                HStack {
                    Spacer()
                    VStack(spacing: 3) {
                        Spacer()
                        Image(systemName: "tray.and.arrow.down")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isTargeted ? .blue : .secondary)
                        Text("Drop APK")
                            .font(.system(size: 8))
                            .foregroundColor(isTargeted ? .blue : .secondary)
                        Spacer()
                    }
                    Spacer()
                }
            }
        )
        .onDrop(of: dropTypes, isTargeted: $isTargeted) { providers in
            guard let provider = providers.first else { return false }

            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadFileRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { tempURL, _ in
                    guard let tempURL else { return }
                    copyToStableTempAndInstall(from: tempURL)
                }
                return true
            }

            if let apk = UTType(filenameExtension: "apk"),
               provider.hasItemConformingToTypeIdentifier(apk.identifier)
            {
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
            do {
                let data = try Data(contentsOf: sourceURL)
                try data.write(to: destURL, options: [.atomic])
                Task { @MainActor in
                    state.installAPK(from: destURL)
                }
            } catch {}
        }
    }

    private func presentFilePicker() {
        guard let url = chooseFile(allowedExtensions: ["apk"]) else { return }
        state.installAPK(from: url)
    }
}
