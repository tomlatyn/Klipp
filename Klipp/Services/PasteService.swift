//
//  PasteService.swift
//  Klipp
//
//  Created by Codex on 18.08.2026.
//

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

final class PasteService {

    private var targetApplication: NSRunningApplication?
    private var activationObserver: NSObjectProtocol?

    func start() {
        guard activationObserver == nil else { return }

        remember(application: NSWorkspace.shared.frontmostApplication)

        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            self?.remember(application: application)
        }
    }

    func prepareForPanel() {
        remember(application: NSWorkspace.shared.frontmostApplication)
    }

    func requestAccessibilityAccessIfNeeded() {
        guard !AXIsProcessTrusted() else { return }

        AppWindows.accessibilityPermission.show {
            AccessibilityPermissionView(
                onEnable: { [weak self] in
                    AppWindows.accessibilityPermission.close()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self?.promptForAccessibilityAccess()
                    }
                },
                onNotNow: {
                    AppWindows.accessibilityPermission.close()
                }
            )
        }
    }

    func paste() {
        guard AXIsProcessTrusted(),
              let targetApplication,
              !targetApplication.isTerminated else {
            requestAccessibilityAccessIfNeeded()
            return
        }

        NSApp.yieldActivation(to: targetApplication)
        _ = targetApplication.activate(from: .current, options: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.postPasteWhenActive(targetApplication, remainingAttempts: 15)
        }
    }

    private func remember(application: NSRunningApplication?) {
        guard let application,
              application.processIdentifier != NSRunningApplication.current.processIdentifier,
              !application.isTerminated else {
            return
        }

        targetApplication = application
    }

    private func promptForAccessibilityAccess() {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func postPasteWhenActive(_ application: NSRunningApplication, remainingAttempts: Int) {
        guard !application.isTerminated else { return }

        if NSWorkspace.shared.frontmostApplication?.processIdentifier == application.processIdentifier {
            postPasteShortcut()
            return
        }

        guard remainingAttempts > 0 else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) { [weak self] in
            self?.postPasteWhenActive(application, remainingAttempts: remainingAttempts - 1)
        }
    }

    private func postPasteShortcut() {
        guard let source = CGEventSource(stateID: .hidSystemState),
              let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false) else {
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
