//
//  SettingsViewController.swift
//  ADB Assistant
//
//  Created by Michael Ovchinnikov on 21/12/2018.
//  Copyright © 2018 Michael Ovchinnikov. All rights reserved.
//

import Cocoa

final class SettingsViewController: NSViewController {
    
    var viewModel: SettingsViewModel?
    
    // MARK: IB bindings
    
    @IBOutlet weak var pathTextField: NSTextField!
    
    @IBAction func didPressChoosePathButton(_ sender: NSButton) {
        let openDialog = NSOpenPanel()
        openDialog.canChooseFiles = false
        openDialog.canChooseDirectories = true
        
        if (openDialog.runModal() == .OK) {
            if let path = openDialog.url?.path {
                viewModel?.platformToolsPath.value = path
            }
        }
    }
    
    @IBAction func didPressCancelButton(_ sender: NSButton) {
        NSApplication.shared.mainWindow?.close()
    }
    
    @IBAction func didPressOKButton(_ sender: NSButton) {
        NSApplication.shared.mainWindow?.close()
        
        let isADBAvailable = viewModel?.isADBAvailable() ?? false
        if isADBAvailable {
            openMainViewController()
            viewModel?.savePlatformToolsPath()
        } else {
            showAlert(header: "Error", text: "ADB binary not found!")
        }
    }
    
    // MARK: View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pathTextField.delegate = self
        
        setupDependencies()
    }
    
    // MARK: Private methods
    
    private func setupDependencies() {
        viewModel = ServiceLocator.shared.settingsViewModel
        bindViewModel()
    }
    
    private func bindViewModel() {
        viewModel?.platformToolsPath.bind { [weak self] (path) in
            self?.pathTextField.stringValue = path ?? ""
        }
    }
    
    private func showAlert(header: String, text: String) {
        let alert = NSAlert.init()
        alert.messageText = header
        alert.informativeText = text
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning
        alert.beginSheetModal(for: self.view.window!,
                              completionHandler: nil)
    }
    
    private func openMainViewController() {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let window = storyboard.instantiateController(withIdentifier: "MainWindow") as! NSWindowController
        let mainViewController = storyboard.instantiateController(withIdentifier: "MainViewController") as! NSViewController
        window.contentViewController = mainViewController
        window.showWindow(self)
    }
    
}

// MARK: - NSTextFieldDelegate

extension SettingsViewController: NSTextFieldDelegate {
    
    func controlTextDidChange(_ obj: Notification) {
        guard
            let textField = obj.object as? NSTextField,
            textField == pathTextField
        else { return }
        
        viewModel?.platformToolsPath.value = pathTextField.stringValue
    }
    
}
