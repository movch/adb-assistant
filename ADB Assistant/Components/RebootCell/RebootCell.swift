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
    
    @IBAction func didPressRebootToROM(_ sender: NSButton) {
        delegate?.didPressRebootToSystem()
    }
    
    @IBAction func didPressRebootToBootloader(_ sender: NSButton) {
        delegate?.didPressRebootToBootloader()
    }
    
    @IBAction func didPressRebootToRecovery(_ sender: NSButton) {
        delegate?.didPressRebootToRecovery()
    }
    
}
