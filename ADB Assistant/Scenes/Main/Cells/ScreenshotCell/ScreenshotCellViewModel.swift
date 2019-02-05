//
//  ScreenshotCellViewModel.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 07/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Cocoa

final class ScreenshotCellViewModel: ActionCellViewModel {
    private(set) var savePath: Dynamic<String> = Dynamic("~/Desktop")
    private(set) var shouldOpenPreview: Dynamic<Bool> = Dynamic(true)

    private let defaults: Defaults

    init(adbWrapper: ADBWrapperType, settings: Defaults) {
        defaults = settings

        super.init(adbWrapper: adbWrapper)

        restoreDefaults()
    }

    private func restoreDefaults() {
        if let savePath = defaults.string(forKey: .screenshotsSavePath) {
            self.savePath.value = savePath
        }

        if let shouldOpenPreview = defaults.bool(forKey: .screenshotsShouldOpenPreview) {
            self.shouldOpenPreview.value = shouldOpenPreview
        }
    }
}

extension ScreenshotCellViewModel: ScreenShotCellViewModelType {
    public func takeScreenshot() {
        guard
            let identifier = self.currentDevice?.identifier,
            let deviceModel = self.currentDevice?.model
        else {
            return
        }

        let modelName = deviceModel.toFilenameString()
        let date = Date().toFilenameString()
        let filename = "\(modelName)-\(date).png"
        let tempDevicePath = "/sdcard/\(filename)"
        let selectedFolder = NSString(string: savePath.value).expandingTildeInPath

        adbWrapper.takeScreenshot(identifier: identifier,
                                  path: tempDevicePath)
        adbWrapper.pull(identifier: identifier,
                        fromPath: tempDevicePath,
                        toPath: selectedFolder)
        adbWrapper.remove(identifier: identifier,
                          path: tempDevicePath)

        if shouldOpenPreview.value {
            let localSreenshotPath = "\(selectedFolder)/\(filename)"
            NSWorkspace.shared.openFile(localSreenshotPath)
        }
    }

    public func updateDefaults() {
        defaults.setBool(shouldOpenPreview.value, forKey: .screenshotsShouldOpenPreview)
        defaults.setString(savePath.value, forKey: .screenshotsSavePath)
    }
}
