//
//  DeviceType.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 01/02/2019.
//  Copyright © 2019 Michael Ovchinnikov. All rights reserved.
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
