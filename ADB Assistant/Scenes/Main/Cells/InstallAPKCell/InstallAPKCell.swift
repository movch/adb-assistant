//
//  InstallAPKCell.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 21/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Cocoa

protocol InstallAPKCellViewModelType {
    func installAPK(atURL URL: NSURL)
}

final class InstallAPKCell: NSTableCellView {
    public var viewModel: InstallAPKCellViewModelType?

    @IBOutlet var dragView: DragView!

    override func awakeFromNib() {
        super.awakeFromNib()

        dragView.delegate = self
        dragView.acceptedFileExtensions = ["apk"]
    }
}

// MARK: - DragViewDelegate

extension InstallAPKCell: DragViewDelegate {
    func dragView(didDragFileWith URL: NSURL) {
        viewModel?.installAPK(atURL: URL)
    }
}
