//
//  Router.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 18/01/2019.
//  Copyright © 2019 Michael Ovchinnikov. All rights reserved.
//

import Cocoa

final class Router {
    let viewControllerFactory: ViewControllerFactory

    init(viewControllerFactory: ViewControllerFactory) {
        self.viewControllerFactory = viewControllerFactory
    }

    func presentMainController() {
        guard
            let window = viewControllerFactory.createMainWindowController(),
            let mainController = viewControllerFactory.createMainViewController()
        else {
            return
        }

        window.contentViewController = mainController
        window.showWindow(self)
    }

    func presentSettingsController() {
        guard
            let window = viewControllerFactory.createMainWindowController(),
            let settingsController = viewControllerFactory.createSettingsViewController()
        else {
            return
        }

        window.contentViewController = settingsController
        window.showWindow(self)
    }
}
