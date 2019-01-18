//
//  DateHelpers.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 07/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

extension Date {
    func toFilenameString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "ddMMyyyy-HHmmss"

        return dateFormatter.string(from: self)
    }
}
