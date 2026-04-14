import AppKit
import SwiftUI

struct SetupView: View {
    @EnvironmentObject private var state: AppState

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Welcome to ADB Assistant")
                    .font(.largeTitle)
                Text("Select the Android Platform Tools folder to get started.")
                    .foregroundColor(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current path")
                        .font(.subheadline)
                        .bold()
                    Text(state.platformToolsPath?.abbreviatingWithTildeInPath() ?? "Not set")
                        .foregroundColor(state.platformToolsPath == nil ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                HStack(spacing: 12) {
                    Button("Choose Folder…") {
                        if let path = pickDirectory(initialPath: state.platformToolsPath) {
                            state.setPlatformToolsPath(path)
                        }
                    }

                    if state.platformToolsPath != nil {
                        Button("Clear") {
                            state.clearPlatformToolsPath()
                        }
                    }
                }

                Text("The selected directory must contain the adb executable (usually the Android Platform Tools folder).")
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: 480)

            Spacer()
        }
        .padding(40)
        .frame(minWidth: 600, minHeight: 360)
        .alert(item: $state.alert) { alert in
            Alert(title: Text(alert.title), message: Text(alert.message))
        }
    }
}

private func pickDirectory(initialPath: String?) -> String? {
    let panel = NSOpenPanel()
    panel.canChooseDirectories = true
    panel.canChooseFiles = false
    panel.allowsMultipleSelection = false
    if let initialPath {
        let expanded = NSString(string: initialPath).expandingTildeInPath
        panel.directoryURL = URL(fileURLWithPath: expanded)
    }
    return panel.runModal() == .OK ? panel.url?.path : nil
}
