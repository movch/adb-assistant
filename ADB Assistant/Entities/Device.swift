//
//  Device.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 28/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

enum DeviceType: String {
    case phone, tablet, watch, tv, auto

    var imageName: String {
        switch self {
        case .phone:
            return "icon-phone"
        case .tablet:
            return "icon-tablet"
        case .watch:
            return "icon-watch"
        case .tv:
            return "icon-tv"
        case .auto:
            return "icon-auto"
        }
    }
}

extension DeviceType {
    init(characteristics: String) {
        if characteristics.range(of: "watch") != nil {
            self = .watch
        } else if characteristics.range(of: "tablet") != nil {
            self = .tablet
        } else if characteristics.range(of: "tv") != nil {
            self = .tv
        } else if characteristics.range(of: "auto") != nil {
            self = .auto
        } else {
            self = .phone
        }
    }
}

struct Device {
    var identifier: String
    var model: String
    var type: DeviceType

    init(identifier: String, properties: Dictionary<String, String>) {
        self.identifier = identifier
        model = properties["ro.product.model"] ?? ""
        type = DeviceType(characteristics: properties["ro.build.characteristics"] ?? "")
    }
}
