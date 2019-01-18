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
        let controller = viewControllerFactory.createMainViewController()
        present(controller)
    }

    func presentSettingsController() {
        let controller = viewControllerFactory.createSettingsViewController()
        present(controller)
    }

    private func present(_ controller: NSViewController?) {
        guard
            let window = viewControllerFactory.createMainWindowController(),
            let controller = controller
        else {
            return
        }

        window.contentViewController = controller
        window.showWindow(self)
    }
}
