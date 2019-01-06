//
//  ADBWrapperMock.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 30/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

final class ADBWrapperMock: ADBWrapperType {
    
    init(shell: ShellType, platformToolsPath: String) {}
    
    func listDeviceIds() -> [String]{
        return ["phone", "tablet", "watch", "tv", "auto"]
    }
    
    func getDevice(forId identifier: String) -> Device {
        return Device(identifier: identifier, properties: [
            "ro.product.model":identifier,
            "ro.build.characteristics":identifier
            ])
    }
    
    public func reboot(to: ADBRebootType, identifier: String) {}
    
    func takeScreenshot(identifier: String, path: String) {}
    
    func pull(identifier: String, fromPath: String, toPath: String) {}
    func remove(identifier: String, path: String) {}
    
    func wakeUpDevice(identifier: String) {}
    
    func installAPK(identifier: String, fromPath path: String) {}
    
}
