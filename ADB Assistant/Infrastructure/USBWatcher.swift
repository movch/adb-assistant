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

/// An object which observes USB devices added and removed from the system.
/// Abstracts away most of the ugliness of IOKit APIs.
public final class USBWatcher: DeviceEventsSource {
    var onDevicesChanged: (() -> Void)?
    private let notificationPort = IONotificationPortCreate(kIOMainPortDefault)
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0

    public init() {
        func handleNotification(instance: UnsafeMutableRawPointer?, _ iterator: io_iterator_t) {
            guard let instance else { return }
            let watcher = Unmanaged<USBWatcher>.fromOpaque(instance).takeUnretainedValue()

            while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                switch iterator {
                case watcher.addedIterator:
                    Task { @MainActor in watcher.onDevicesChanged?() }
                case watcher.removedIterator:
                    Task { @MainActor in watcher.onDevicesChanged?() }
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

final class USBWatcherFactory: DeviceEventsSourceFactory {
    func makeSource() -> DeviceEventsSource {
        USBWatcher()
    }
}
