import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct PreferencesView: View {
    @EnvironmentObject private var state: AppState
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Preferences")
                .font(.title)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Android Platform Tools")
                        .font(.headline)

                    SettingsPathRow(
                        label: "Current path",
                        value: state.platformToolsPath?.abbreviatingWithTildeInPath() ?? "Not set"
                    )

                    HStack {
                        Button("Choose Folder…") {
                            if let path = chooseDirectory(initialPath: state.platformToolsPath) {
                                state.setPlatformToolsPath(path)
                            }
                        }
                        Button("Clear") {
                            state.clearPlatformToolsPath()
                        }
                        .disabled(state.platformToolsPath == nil)
                    }
                }

            }
            
            Spacer()

            HStack {
                Spacer()
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 480)
    }
}

struct SettingsPathRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .bold()
            Text(value)
                .font(.body)
                .foregroundColor(value == "Not set" ? .secondary : .primary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

func chooseDirectory(initialPath: String?) -> String? {
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

func chooseFile(allowedExtensions: [String]) -> URL? {
    let panel = NSOpenPanel()
    panel.canChooseFiles = true
    panel.canChooseDirectories = false
    panel.allowsMultipleSelection = false
    let contentTypes = allowedExtensions.compactMap { UTType(filenameExtension: $0) }
    panel.allowedContentTypes = contentTypes
    return panel.runModal() == .OK ? panel.url : nil
}
