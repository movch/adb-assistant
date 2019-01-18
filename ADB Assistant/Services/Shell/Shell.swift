//
//  ShellTask.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 25/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

final class Shell: ShellType {
    public func execute(_ command: String) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let outputPipe = Pipe()
        task.standardOutput = outputPipe
        let file = outputPipe.fileHandleForReading

        task.launch()

        if let result = NSString(data: file.readDataToEndOfFile(),
                                 encoding: String.Encoding.utf8.rawValue) {
            return (result as String).trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return ""
    }
}
