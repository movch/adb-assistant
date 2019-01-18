//
//  ViewControllerFactory.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 18/01/2019.
//  Copyright © 2019 Michael Ovchinnikov. All rights reserved.
//

import Cocoa

final class ViewControllerFactory {
    let storyboard: NSStoryboard

    init(storyboard: NSStoryboard) {
        self.storyboard = storyboard
    }

    public func createMainWindowController() -> NSWindowController? {
        return storyboard.instantiateController(withIdentifier: "MainWindow") as? NSWindowController
    }

    public func createMainViewController() -> MainViewController? {
        return storyboard.instantiateController(withIdentifier: "MainViewController") as? MainViewController
    }

    public func createSettingsViewController() -> SettingsViewController? {
        return storyboard.instantiateController(withIdentifier: "SettingsViewController") as? SettingsViewController
    }
}
