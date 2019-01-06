//
//  ScreenshotCell.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 07/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import AppKit

protocol ScreenshotCellDelegate: class {
    
    func didPressTakeScreenshotButton()
    func didPressSelectSaveFolderButton()
    func didSwitchOpenInPreviewCheckbox(on: Bool)
    
}

protocol ScreenshotCellDataSource: class {
    
    func screenshotSavePath() -> String
    func openInPreviewCheckBoxState() -> Bool
    
}

final class ScreenshotCell: NSTableCellView {
    
    public weak var delegate: ScreenshotCellDelegate?
    public weak var dataSource: ScreenshotCellDataSource?
    
    @IBOutlet weak var screenshotSavePathLabel: NSTextField!
    @IBOutlet weak var openInPreviewCheckbox: NSButton!
    
    @IBAction func didPressTakeScreenshotButton(_ sender: NSButton) {
        delegate?.didPressTakeScreenshotButton()
    }
    
    @IBAction func didPressSelectFolderButton(_ sender: NSButton) {
        delegate?.didPressSelectSaveFolderButton()
    }
    
    @IBAction func didSwitchOpenInPreviewCheckbox(_ sender: NSButton) {
        let state = sender.state == .on
        delegate?.didSwitchOpenInPreviewCheckbox(on: state)
    }
    
    public func reloadData() {
        screenshotSavePathLabel.stringValue = dataSource?.screenshotSavePath() ?? ""
        openInPreviewCheckbox.state = dataSource?.openInPreviewCheckBoxState() ?? false ? .on : .off
    }
    
}
