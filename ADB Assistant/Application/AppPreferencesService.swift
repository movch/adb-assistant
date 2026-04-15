import Foundation

struct AppPreferences {
    let platformToolsPath: String?
    let screenshotSavePath: String
    let shouldOpenPreview: Bool
}

struct AppPreferencesService {
    private let store: PreferencesStore

    init(store: PreferencesStore) {
        self.store = store
    }

    func load() -> AppPreferences {
        AppPreferences(
            platformToolsPath: store.string(forKey: .platformToolsPath),
            screenshotSavePath: store.string(forKey: .screenshotsSavePath) ?? "~/Desktop",
            shouldOpenPreview: store.bool(forKey: .screenshotsShouldOpenPreview) ?? true
        )
    }

    func setPlatformToolsPath(_ path: String) {
        store.setString(path, forKey: .platformToolsPath)
    }

    func clearPlatformToolsPath() {
        store.removeValue(forKey: .platformToolsPath)
    }

    func setScreenshotSavePath(_ path: String) {
        store.setString(path, forKey: .screenshotsSavePath)
    }

    func setShouldOpenPreview(_ flag: Bool) {
        store.setBool(flag, forKey: .screenshotsShouldOpenPreview)
    }

    func validateADB(at path: String) -> Bool {
        let adbPath = URL(fileURLWithPath: path).appendingPathComponent("adb").path
        return FileManager.default.fileExists(atPath: adbPath)
    }
}
