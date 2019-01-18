//
//  ViewController.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 25/11/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Cocoa

enum ToolSection: Int, CaseIterable {
    case reboot, screenshot, installAPK
}

final class MainViewController: NSViewController {
    var sidebarViewModel: SideBarViewModel?
    var rebootViewModel: RebootSectionViewModel?
    var screenshotViewModel: ScreenshotSectionViewModel?
    var installAPKViewModel: InstallAPKSectionViewModel?
    var usbWatcher: USBWatcher?

    // MARK: IB Bindings

    @IBOutlet var sideTableView: NSTableView!
    @IBOutlet var toolsTableView: NSTableView!
    @IBOutlet var placeholderLabel: NSTextField!

    @IBAction func didSelectRow(_: NSTableView) {
        let selectedRow = sideTableView.selectedRow
        sidebarViewModel?.selectDevice(atIndex: selectedRow)
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupDependencies()
        setupSideTableView()
        setupToolsTableView()
        setToolsTableViewVisibility()
    }

    // MARK: Setup methods

    private func setupDependencies() {
        sidebarViewModel = ServiceLocator.shared.sidebarViewModel
        rebootViewModel = ServiceLocator.shared.rebootViewModel
        screenshotViewModel = ServiceLocator.shared.screenshotViewModel
        installAPKViewModel = ServiceLocator.shared.installAPKViewModel

        bindSidebarViewModel()
        bindScreenshotViewModel()

        usbWatcher = USBWatcher(delegate: self)
    }

    private func bindSidebarViewModel() {
        sidebarViewModel?.devices.bind { [weak self] _ in
            self?.sideTableView.reloadData()
            self?.setToolsTableViewVisibility()
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

    private func bindScreenshotViewModel() {
        let screenshotBinding: (Any) -> Void = { [weak self] _ in
            self?.toolsTableView.reloadData(forRowIndexes: [ToolSection.screenshot.rawValue],
                                            columnIndexes: [0])
            self?.screenshotViewModel?.updateDefaults()
        }

        screenshotViewModel?.savePath.bind(listener: screenshotBinding)
        screenshotViewModel?.shouldOpenPreview.bind(listener: screenshotBinding)
    }

    private func setupSideTableView() {
        sideTableView.dataSource = self
        sideTableView.delegate = self
    }

    private func setupToolsTableView() {
        toolsTableView.dataSource = self
        toolsTableView.delegate = self

        toolsTableView.register(NSNib(nibNamed: String(describing: RebootCell.self),
                                      bundle: nil),
                                forIdentifier: .rebootCellID)
        toolsTableView.register(NSNib(nibNamed: String(describing: ScreenshotCell.self),
                                      bundle: nil),
                                forIdentifier: .screenshotCellID)
        toolsTableView.register(NSNib(nibNamed: String(describing: InstallAPKCell.self),
                                      bundle: nil),
                                forIdentifier: .installAPKCellID)
    }

    private func setToolsTableViewVisibility() {
        guard let viewModel = sidebarViewModel else { return }
        toolsTableView.isHidden = viewModel.devices.value.count > 0 ? false : true
        placeholderLabel.isHidden = !toolsTableView.isHidden
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
        if tableView == toolsTableView {
            return ToolSection.allCases.count
        }

        return sidebarViewModel?.devicesCount ?? 0
    }
}

// MARK: - NSTableViewDelegate

extension MainViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor _: NSTableColumn?, row: Int) -> NSView? {
        if tableView == toolsTableView {
            let toolSection = ToolSection(rawValue: row)!
            switch toolSection {
            case .reboot:
                let cell = tableView.makeView(withIdentifier: .rebootCellID, owner: nil) as? RebootCell
                cell?.delegate = self
                return cell
            case .screenshot:
                let cell = tableView.makeView(withIdentifier: .screenshotCellID, owner: nil) as? ScreenshotCell
                cell?.delegate = self
                cell?.dataSource = self
                cell?.reloadData()
                return cell
            case .installAPK:
                let cell = tableView.makeView(withIdentifier: .installAPKCellID, owner: nil) as? InstallAPKCell
                cell?.dragView.delegate = self
                return cell
            }
        }

        guard
            let cell = tableView.makeView(withIdentifier: .sideBarCellID, owner: nil) as? NSTableCellView,
            let device = sidebarViewModel?.devices.value[row]
        else { return nil }

        cell.textField?.stringValue = device.model
        cell.imageView?.image = NSImage(named: device.type.imageName)

        return cell
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView == toolsTableView {
            let toolSection = ToolSection(rawValue: row)!
            switch toolSection {
            case .reboot:
                return 54.0
            case .screenshot:
                return 102.0
            case .installAPK:
                return 150.0
            }
        }

        return 17.0
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow _: Int) -> Bool {
        if tableView == toolsTableView {
            return false
        }

        return true
    }
}

// MARK: - USBWatcherDelegate

extension MainViewController: USBWatcherDelegate {
    func deviceAdded(_: io_object_t) {
        // We have to introduce delay
        // as some time is needed to recognize a USB device
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1000)) {
            self.sidebarViewModel?.fetchDeviceList()
        }
    }

    func deviceRemoved(_: io_object_t) {
        sidebarViewModel?.fetchDeviceList()
    }
}

// MARK: - RebootCellDelegate

extension MainViewController: RebootCellDelegate {
    func didPressRebootToSystem() {
        rebootViewModel?.reboot(to: .system)
    }

    func didPressRebootToBootloader() {
        rebootViewModel?.reboot(to: .bootloader)
    }

    func didPressRebootToRecovery() {
        rebootViewModel?.reboot(to: .recovery)
    }
}

// MARK: - ScreenshotCellDelegate

extension MainViewController: ScreenshotCellDelegate {
    func didPressTakeScreenshotButton() {
        screenshotViewModel?.takeScreenshot()
    }

    func didPressSelectSaveFolderButton() {
        let openDialog = NSOpenPanel()
        openDialog.canChooseFiles = false
        openDialog.canChooseDirectories = true

        if openDialog.runModal() == .OK {
            if let path = openDialog.url?.path {
                screenshotViewModel?.savePath.value = path
            }
        }
    }

    func didSwitchOpenInPreviewCheckbox(on: Bool) {
        screenshotViewModel?.shouldOpenPreview.value = on
    }
}

// MARK: - ScreenshotCellDataSource

extension MainViewController: ScreenshotCellDataSource {
    func screenshotSavePath() -> String {
        return screenshotViewModel?.savePath.value ?? "N/A"
    }

    func openInPreviewCheckBoxState() -> Bool {
        return screenshotViewModel?.shouldOpenPreview.value ?? true
    }
}

// MARK: - InstallAPKCell DragViewDelegate

extension MainViewController: DragViewDelegate {
    func dragView(didDragFileWith URL: NSURL) {
        installAPKViewModel?.installAPK(atURL: URL)
    }
}
