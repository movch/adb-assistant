//
//  MainViewController.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 25/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Cocoa

enum ActionType: Int, CaseIterable {
    case reboot, screenshot, installAPK

    var cellSize: CGFloat {
        switch self {
        case .reboot:
            return 54.0
        case .screenshot:
            return 102.0
        case .installAPK:
            return 150.0
        }
    }
}

final class MainViewController: NSViewController {
    var sidebarViewModel: SideBarViewModel?
    var rebootViewModel: RebootCellViewModel?
    var screenshotViewModel: ScreenshotCellViewModel?
    var installAPKViewModel: InstallAPKCellViewModel?
    var usbWatcher: USBWatcher?

    // MARK: IB Bindings

    @IBOutlet var sideTableView: NSTableView!
    @IBOutlet var actionsTableView: NSTableView!
    @IBOutlet var placeholderLabel: NSTextField!

    @IBAction func didSelectRow(_: NSTableView) {
        let selectedRow = sideTableView.selectedRow
        sidebarViewModel?.selectDevice(atIndex: selectedRow)
    }

    @IBAction func didPressRefreshButton(_: NSButton) {
        sidebarViewModel?.fetchDeviceList()
    }

    @IBAction func didPressSettingsButton(_: NSButton) {
        let router = ServiceLocator.shared.router
        router.presentSettingsController()
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDependencies()
        setupSideTableView()
        setupActionsTableView()
        setActionsTableViewVisibility()

        sidebarViewModel?.fetchDeviceList()
    }

    // MARK: View Setup

    private func setupDependencies() {
        sidebarViewModel = ServiceLocator.shared.sidebarViewModel
        rebootViewModel = ServiceLocator.shared.rebootViewModel
        screenshotViewModel = ServiceLocator.shared.screenshotViewModel
        installAPKViewModel = ServiceLocator.shared.installAPKViewModel

        bindSidebarViewModel()

        usbWatcher = USBWatcher(delegate: self)
    }

    private func bindSidebarViewModel() {
        sidebarViewModel?.devices.bind { [weak self] _ in
            self?.sideTableView.reloadData()
            self?.setActionsTableViewVisibility()
        }

        sidebarViewModel?.selectedDeviceIndex.bind { [weak self] index in
            guard let i = index, i >= 0 else { return }
            self?.sideTableView.selectRowIndexes([i], byExtendingSelection: false)

            guard let device = self?.sidebarViewModel?.devices.value[i] else { return }
            self?.rebootViewModel?.currentDevice = device
            self?.screenshotViewModel?.currentDevice = device
            self?.installAPKViewModel?.currentDevice = device
        }
    }

    private func setupSideTableView() {
        sideTableView.dataSource = self
        sideTableView.delegate = self
    }

    private func setupActionsTableView() {
        actionsTableView.dataSource = self
        actionsTableView.delegate = self

        actionsTableView.register(NSNib(nibNamed: String(describing: RebootCell.self),
                                        bundle: nil),
                                  forIdentifier: .rebootCellID)
        actionsTableView.register(NSNib(nibNamed: String(describing: ScreenshotCell.self),
                                        bundle: nil),
                                  forIdentifier: .screenshotCellID)
        actionsTableView.register(NSNib(nibNamed: String(describing: InstallAPKCell.self),
                                        bundle: nil),
                                  forIdentifier: .installAPKCellID)
    }

    private func setActionsTableViewVisibility() {
        guard let viewModel = sidebarViewModel else { return }
        actionsTableView.isHidden = viewModel.devices.value.count > 0 ? false : true
        placeholderLabel.isHidden = !actionsTableView.isHidden
    }
}

// MARK: - NSUserInterfaceItemIdentifier

extension NSUserInterfaceItemIdentifier {
    static let sideBarCellID = NSUserInterfaceItemIdentifier("sideBarCellID")
    static let rebootCellID = NSUserInterfaceItemIdentifier(String(describing: RebootCell.self))
    static let screenshotCellID = NSUserInterfaceItemIdentifier(String(describing: ScreenshotCell.self))
    static let installAPKCellID = NSUserInterfaceItemIdentifier(String(describing: InstallAPKCell.self))
}

// MARK: - NSTableViewDataSource

extension MainViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == actionsTableView {
            return ActionType.allCases.count
        }

        return sidebarViewModel?.devicesCount ?? 0
    }
}

// MARK: - NSTableViewDelegate

extension MainViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        if tableView == actionsTableView,
            let cellType = ActionType(rawValue: row) {
            switch cellType {
            case .reboot:
                return rebootCell(tableView)
            case .screenshot:
                return screenshotCell(tableView)
            case .installAPK:
                return installAPKCell(tableView)
            }
        }

        return sidebarCell(tableView, row: row)
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView == actionsTableView,
            let cellType = ActionType(rawValue: row) {
            return cellType.cellSize
        }

        return 17.0
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow _: Int) -> Bool {
        if tableView == actionsTableView {
            return false
        }

        return true
    }

    // MARK: Cell configuration

    func rebootCell(_ tableView: NSTableView) -> NSView? {
        let cell = tableView.makeView(withIdentifier: .rebootCellID, owner: nil) as? RebootCell
        cell?.viewModel = rebootViewModel
        return cell
    }

    func screenshotCell(_ tableView: NSTableView) -> NSView? {
        let cell = tableView.makeView(withIdentifier: .screenshotCellID, owner: nil) as? ScreenshotCell
        cell?.viewModel = screenshotViewModel
        return cell
    }

    func installAPKCell(_ tableView: NSTableView) -> NSView? {
        let cell = tableView.makeView(withIdentifier: .installAPKCellID, owner: nil) as? InstallAPKCell
        cell?.viewModel = installAPKViewModel
        return cell
    }

    func sidebarCell(_ tableView: NSTableView, row: Int) -> NSView? {
        guard
            let cell = tableView.makeView(withIdentifier: .sideBarCellID, owner: nil) as? NSTableCellView,
            let device = sidebarViewModel?.devices.value[row]
        else {
            return nil
        }

        cell.textField?.stringValue = device.model
        cell.imageView?.image = NSImage(named: device.type.imageName)

        return cell
    }
}

// MARK: - USBWatcherDelegate

extension MainViewController: USBWatcherDelegate {
    func deviceAdded(_: io_object_t) {
        // We have to introduce delay as some time is needed
        // to recognize a USB device
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            self.sidebarViewModel?.fetchDeviceList()
        }
    }

    func deviceRemoved(_: io_object_t) {
        sidebarViewModel?.fetchDeviceList()
    }
}
