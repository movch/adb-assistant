//
//  RebootCell.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 07/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import AppKit

protocol RebootCellDelegate: class {
    func didPressRebootToSystem()
    func didPressRebootToBootloader()
    func didPressRebootToRecovery()
}

final class RebootCell: NSTableCellView {
    public weak var delegate: RebootCellDelegate?

    @IBAction func didPressRebootToROM(_: NSButton) {
        delegate?.didPressRebootToSystem()
    }

    @IBAction func didPressRebootToBootloader(_: NSButton) {
        delegate?.didPressRebootToBootloader()
    }

    @IBAction func didPressRebootToRecovery(_: NSButton) {
        delegate?.didPressRebootToRecovery()
    }
}
