//
//  USBWatcher.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 26/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Foundation
import IOKit

private let usbDeviceClassName = "IOUSBDevice"

@MainActor
public protocol USBWatcherDelegate: AnyObject {
    /// Called on the main thread when a device is connected.
    func deviceAdded(_ device: io_object_t)

    /// Called on the main thread when a device is disconnected.
    func deviceRemoved(_ device: io_object_t)
}

/// An object which observes USB devices added and removed from the system.
/// Abstracts away most of the ugliness of IOKit APIs.
public class USBWatcher {
    private weak var delegate: USBWatcherDelegate?
    private let notificationPort = IONotificationPortCreate(kIOMainPortDefault)
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0

    public init(delegate: USBWatcherDelegate) {
        self.delegate = delegate

        func handleNotification(instance: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
            guard let instance else { return }
            let watcher = Unmanaged<USBWatcher>.fromOpaque(instance).takeUnretainedValue()

            while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                switch iterator {
                case watcher.addedIterator:
                    if let delegate = watcher.delegate {
                        Task { @MainActor in delegate.deviceAdded(device) }
                    }
                case watcher.removedIterator:
                    if let delegate = watcher.delegate {
                        Task { @MainActor in delegate.deviceRemoved(device) }
                    }
                default:
                    assertionFailure("received unexpected IOIterator")
                }
                IOObjectRelease(device)
            }
        }

        let query = usbDeviceClassName.withCString { IOServiceMatching($0) }
        let opaqueSelf = Unmanaged.passUnretained(self).toOpaque()

        // Watch for connected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOMatchedNotification, query,
            handleNotification, opaqueSelf, &addedIterator
        )

        handleNotification(instance: opaqueSelf, addedIterator)

        // Watch for disconnected devices.
        IOServiceAddMatchingNotification(
            notificationPort, kIOTerminatedNotification, query,
            handleNotification, opaqueSelf, &removedIterator
        )

        handleNotification(instance: opaqueSelf, removedIterator)

        // Add the notification to the main run loop to receive future updates.
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue(),
            .commonModes
        )
    }

    deinit {
        IOObjectRelease(addedIterator)
        IOObjectRelease(removedIterator)
        IONotificationPortDestroy(notificationPort)
    }
}

extension io_object_t {
    /// - Returns: The device's name.
    func name() -> String? {
        let buf = UnsafeMutablePointer<io_name_t>.allocate(capacity: 1)
        defer { buf.deallocate() }
        return buf.withMemoryRebound(to: CChar.self, capacity: MemoryLayout<io_name_t>.size) {
            if IORegistryEntryGetName(self, $0) == KERN_SUCCESS {
                return String(cString: $0)
            }
            return nil
        }
    }
}
