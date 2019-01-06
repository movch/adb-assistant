//
//  ToolsViewModel.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 02/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

final class RebootSectionViewModel: ToolSectionViewModel {
    
    public func reboot(to: ADBRebootType) {
        guard let identifier = currentDevice?.identifier else { return }
        adbWrapper.reboot(to: to, identifier: identifier)
    }
    
}
