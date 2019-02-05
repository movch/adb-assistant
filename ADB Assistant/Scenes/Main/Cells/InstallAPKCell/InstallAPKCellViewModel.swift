//
//  InstallAPKCellViewModel.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 21/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

final class InstallAPKCellViewModel: ActionCellViewModel {}

extension InstallAPKCellViewModel: InstallAPKCellViewModelType {
    public func installAPK(atURL URL: NSURL) {
        guard
            let identifier = currentDevice?.identifier,
            let path = URL.path
        else {
            return
        }

        adbWrapper.installAPK(identifier: identifier, fromPath: path)
    }
}
