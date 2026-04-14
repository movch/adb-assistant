import Foundation

enum PreferencesKey: String {
    case screenshotsSavePath
    case screenshotsShouldOpenPreview
    case platformToolsPath
}

protocol PreferencesStore {
    func setString(_ value: String, forKey key: PreferencesKey)
    func string(forKey key: PreferencesKey) -> String?
    func setBool(_ value: Bool, forKey key: PreferencesKey)
    func bool(forKey key: PreferencesKey) -> Bool?
    func removeValue(forKey key: PreferencesKey)
}
