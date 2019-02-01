//
//  ToolSectionViewModel.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 07/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

class ActionCellViewModel {
    public var currentDevice: Device?

    var adbWrapper: ADBWrapperType

    init(adbWrapper: ADBWrapperType) {
        self.adbWrapper = adbWrapper
    }
}
