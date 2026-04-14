//
//  Shell.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 25/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

protocol Shell {
    func execute(_ command: String) throws -> String
}
