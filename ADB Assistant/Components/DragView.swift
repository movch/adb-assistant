//
//  DragView.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 21/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Cocoa

protocol DragViewDelegate: class {
    func dragView(didDragFileWith URL: NSURL)
}

final class DragView: NSView {
    public weak var delegate: DragViewDelegate?
    public var acceptedFileExtensions = ["*"]

    private var fileTypeIsOk = false

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // dash customization parameters
        let dashHeight: CGFloat = 3
        let dashLength: CGFloat = 10
        let dashColor: NSColor = .placeholderTextColor

        // setup the context
        let currentContext = NSGraphicsContext.current?.cgContext
        currentContext?.setLineWidth(dashHeight)
        currentContext?.setLineDash(phase: 0, lengths: [dashLength])
        currentContext?.setStrokeColor(dashColor.cgColor)

        // draw the dashed path
        currentContext?.addRect(bounds.insetBy(dx: dashHeight, dy: dashHeight))
        currentContext?.strokePath()
    }

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)

        registerForDraggedTypes([NSPasteboard.PasteboardType.fileURL])
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        fileTypeIsOk = checkExtension(drag: sender)
        return []
    }

    override func draggingUpdated(_: NSDraggingInfo) -> NSDragOperation {
        return fileTypeIsOk ? .copy : []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let draggedFileURL = sender.draggedFileURL else {
            return false
        }

        if fileTypeIsOk {
            delegate?.dragView(didDragFileWith: draggedFileURL)
        }

        return true
    }

    fileprivate func checkExtension(drag: NSDraggingInfo) -> Bool {
        guard
            let fileExtension = drag.draggedFileURL?.pathExtension?.lowercased()
        else {
            return false
        }

        if acceptedFileExtensions.contains("*") {
            return true
        }

        return acceptedFileExtensions.contains(fileExtension)
    }
}

extension NSDraggingInfo {
    var draggedFileURL: NSURL? {
        return draggingPasteboard
            .readObjects(forClasses: [NSURL.self],
                         options: nil)?
            .first as? NSURL
    }
}
