//
//  PanelController.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import AppKit
import SwiftUI

final class KeyablePanel: NSPanel {

    override var canBecomeKey: Bool { true }
}

final class PanelController: NSObject, NSWindowDelegate {

    static let shared = PanelController()

    weak var store: KlippStore?

    private var panel: KeyablePanel?
    private var keyMonitor: Any?
    private var suppressResignClose = false

    private static let digitKeyCodes: [UInt16: Int] = [
        18: 0, 19: 1, 20: 2, 21: 3, 23: 4, 22: 5, 26: 6, 28: 7, 25: 8
    ]

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func show() {
        guard let store else { return }

        if panel == nil {
            createPanel(store: store)
        }

        applySize()
        positionOnMouseScreen()
        panel?.makeKeyAndOrderFront(nil)
        panel?.invalidateShadow()
        installKeyMonitor()
    }

    func hide() {
        removeKeyMonitor()
        panel?.orderOut(nil)
    }

    @discardableResult
    func confirmClearHistory(completion: @escaping (Bool) -> Void) -> Bool {
        guard let panel, isVisible else { return false }

        let alert = NSAlert()
        alert.messageText = String(localized: .clearClipboardHistoryQuestion)
        alert.informativeText = String(localized: .clearClipboardHistoryMessage)
        alert.alertStyle = .warning
        alert.addButton(withTitle: String(localized: .clearHistory))
        alert.addButton(withTitle: String(localized: .cancel))

        suppressResignClose = true
        alert.beginSheetModal(for: panel) { [weak self] response in
            guard let self else { return }

            self.suppressResignClose = false
            self.panel?.makeKeyAndOrderFront(nil)
            completion(response == .alertFirstButtonReturn)
        }

        return true
    }

    func applySize() {
        guard let panel, let store else { return }

        let size = HistoryPanelFeature.panelSize(for: store.state.panel)
        var frame = panel.frame
        let topCenter = NSPoint(x: frame.midX, y: frame.maxY)
        frame.size = size
        frame.origin = NSPoint(x: topCenter.x - size.width / 2, y: topCenter.y - size.height)
        panel.setFrame(clamped(frame), display: true)
        panel.invalidateShadow()
    }

    private func clamped(_ frame: NSRect) -> NSRect {
        guard let visibleFrame = (panel?.screen ?? NSScreen.main)?.visibleFrame else { return frame }

        var frame = frame
        frame.origin.x = min(max(frame.origin.x, visibleFrame.minX), visibleFrame.maxX - frame.width)
        frame.origin.y = min(max(frame.origin.y, visibleFrame.minY), visibleFrame.maxY - frame.height)
        return frame
    }

    private func createPanel(store: KlippStore) {
        let panel = KeyablePanel(
            contentRect: NSRect(origin: .zero, size: HistoryPanelFeature.panelSize(for: store.state.panel)),
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.animationBehavior = .utilityWindow
        panel.delegate = self

        let hostingView = NSHostingView(rootView: HistoryPanelView(store: store))
        hostingView.sizingOptions = []
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = AppTheme.CornerRadius.panel
        hostingView.layer?.cornerCurve = .continuous
        hostingView.layer?.masksToBounds = true
        panel.contentView = hostingView

        self.panel = panel
    }

    private func positionOnMouseScreen() {
        guard let panel else { return }

        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouseLocation, $0.frame, false) }
            ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else { return }

        let size = panel.frame.size
        let origin = NSPoint(
            x: visibleFrame.midX - size.width / 2,
            y: visibleFrame.minY + visibleFrame.height * 0.62 - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, let store = self.store, self.isVisible else { return event }
            guard event.window === self.panel else { return event }

            let hasCommand = event.modifierFlags.contains(.command)

            if hasCommand, let digit = Self.digitKeyCodes[event.keyCode] {
                store.send(.panel(.activateIndex(digit)))
                return nil
            }

            if hasCommand, event.keyCode == 35 {
                if let selectedID = store.state.panel.selectedID {
                    store.send(.panel(.togglePin(selectedID)))
                }
                return nil
            }

            switch event.keyCode {
            case 53:
                store.send(.panel(.close))
                return nil
            case 125:
                store.send(.panel(.moveSelection(1)))
                return nil
            case 126:
                store.send(.panel(.moveSelection(-1)))
                return nil
            case 36, 76:
                store.send(.panel(.activateSelected))
                return nil
            case 51, 117:
                guard store.state.panel.searchText.isEmpty,
                      let selectedID = store.state.panel.selectedID else {
                    return event
                }
                store.send(.panel(.deleteItem(selectedID)))
                return nil
            case 48:
                store.send(.panel(.toggleMode))
                return nil
            default:
                return event
            }
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        guard (notification.object as? NSWindow) === panel, isVisible else { return }
        guard !suppressResignClose else { return }
        store?.send(.panel(.resignedKey))
    }
}
