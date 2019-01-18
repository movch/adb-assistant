//
//  StringHelpers.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 07/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

extension String {
    func toFilenameString() -> String {
        return lowercased()
            .replacingOccurrences(of: " ", with: "-")
    }
}
