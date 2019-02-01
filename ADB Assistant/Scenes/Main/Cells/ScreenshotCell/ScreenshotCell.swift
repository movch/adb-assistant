//
//  ScreenshotCell.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 07/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import AppKit

protocol ScreenShotCellViewModelType {
    var savePath: Dynamic<String> { get }
    var shouldOpenPreview: Dynamic<Bool> { get }

    func takeScreenshot()
    func updateDefaults()
}

final class ScreenshotCell: NSTableCellView {
    public var viewModel: ScreenShotCellViewModelType?

    @IBOutlet var screenshotSavePathLabel: NSTextField!
    @IBOutlet var openInPreviewCheckbox: NSButton!

    @IBAction func didPressTakeScreenshotButton(_: NSButton) {
        viewModel?.takeScreenshot()
    }

    @IBAction func didPressSelectFolderButton(_: NSButton) {
        let openDialog = NSOpenPanel()
        openDialog.canChooseFiles = false
        openDialog.canChooseDirectories = true

        if openDialog.runModal() == .OK {
            if let path = openDialog.url?.path {
                viewModel?.savePath.value = path
            }
        }
    }

    @IBAction func didSwitchOpenInPreviewCheckbox(_ sender: NSButton) {
        let state = sender.state == .on
        viewModel?.shouldOpenPreview.value = state
    }

    override func layout() {
        super.layout()

        bindViewModel()
    }

    private func bindViewModel() {
        viewModel?.savePath.bindAndFire { [weak self] path in
            self?.screenshotSavePathLabel.stringValue = path
            self?.viewModel?.updateDefaults()
        }
        viewModel?.shouldOpenPreview.bindAndFire { [weak self] openInPreview in
            self?.openInPreviewCheckbox.state = openInPreview ? .on : .off
            self?.viewModel?.updateDefaults()
        }
    }
}
