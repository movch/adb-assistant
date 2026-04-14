//
//  Bash.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 25/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation

enum BashError: Error {
    case processFailed(String)
    case outputEncodingFailed
    case taskExecutionFailed(String)
}

final class Bash: Shell {
    public func execute(_ command: String) throws -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        let file = outputPipe.fileHandleForReading

        do {
            try task.run()
        } catch {
            throw BashError.taskExecutionFailed("Failed to launch process: \(error.localizedDescription)")
        }

        task.waitUntilExit()

        if task.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if let errorString = String(data: errorData, encoding: .utf8) {
                throw BashError.processFailed(errorString)
            } else {
                throw BashError.processFailed("Process exited with status \(task.terminationStatus)")
            }
        }

        let outputData = file.readDataToEndOfFile()
        guard let result = String(data: outputData, encoding: .utf8) else {
            throw BashError.outputEncodingFailed
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
