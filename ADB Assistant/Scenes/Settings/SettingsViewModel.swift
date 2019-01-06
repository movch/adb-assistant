//
//  SettingsViewModel.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 21/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

final class SettingsViewModel {
    
    public var platformToolsPath: Dynamic<String?> = Dynamic(nil)
    
    public func loadPlatformToolsPath() {
        platformToolsPath.value = Defaults().string(forKey: .platformToolsPath)
    }
    
    public func savePlatformToolsPath() {
        Defaults().setString(platformToolsPath.value ?? "",
                             forKey: .platformToolsPath)
    }
    
    public func isADBAvailable() -> Bool {
        return FileManager.default.fileExists(atPath: "\(platformToolsPath.value ?? "")/adb")
    }
    
}
