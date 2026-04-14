//
//  ADBWrapperType.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 30/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

final class ADBDeviceGatewayFactory: DeviceGatewayFactory {
    private let shell: Shell

    init(shell: Shell) {
        self.shell = shell
    }

    func makeGateway(platformToolsPath: String) -> DeviceGateway {
        ADBWrapper(shell: shell, platformToolsPath: platformToolsPath)
    }
}
