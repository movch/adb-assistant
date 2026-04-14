//
//  Device.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 28/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

struct Device {
    let identifier: String
    let model: String

    init(identifier: String, properties: [String: String]) {
        self.identifier = identifier
        model = properties["ro.product.model"] ?? "unknown"
    }
}

extension Device: Identifiable {
    var id: String { identifier }
}

enum RebootType: String {
    case bootloader
    case recovery
    case system = ""
}
