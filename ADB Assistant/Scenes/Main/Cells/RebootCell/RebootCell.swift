//
//  RebootCell.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 07/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import AppKit

protocol RebootCellViewModelType {
    func reboot(to: ADBRebootType)
}

final class RebootCell: NSTableCellView {
    public var viewModel: RebootCellViewModelType?

    @IBAction func didPressRebootToROM(_: NSButton) {
        viewModel?.reboot(to: .system)
    }

    @IBAction func didPressRebootToBootloader(_: NSButton) {
        viewModel?.reboot(to: .bootloader)
    }

    @IBAction func didPressRebootToRecovery(_: NSButton) {
        viewModel?.reboot(to: .recovery)
    }
}
