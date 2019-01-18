//
//  ServiceLocator.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 17/01/2019.
//  Copyright © 2019 Michael Ovchinnikov. All rights reserved.
//

import Foundation

final class ServiceLocator {
    
    static let shared = ServiceLocator()
    
    let shell = Shell()
    let defaults = Defaults()
    let adbWrapper: ADBWrapperType
    
    let sidebarViewModel: SideBarViewModel
    let rebootViewModel: RebootSectionViewModel
    let screenshotViewModel: ScreenshotSectionViewModel
    let installAPKViewModel: InstallAPKSectionViewModel
    let settingsViewModel: SettingsViewModel
    
    private init() {
        let platformToolsPath = defaults.string(forKey: .platformToolsPath) ?? ""
        adbWrapper = ADBWrapperMock(shell: shell, platformToolsPath: platformToolsPath)
        
        sidebarViewModel = SideBarViewModel(adbWrapper: adbWrapper)
        rebootViewModel = RebootSectionViewModel(adbWrapper: adbWrapper)
        screenshotViewModel = ScreenshotSectionViewModel(adbWrapper: adbWrapper, settings: defaults)
        installAPKViewModel = InstallAPKSectionViewModel(adbWrapper: adbWrapper)
        settingsViewModel = SettingsViewModel(settings: defaults)
    }
    
}
