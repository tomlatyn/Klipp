//
//  WindowControllers.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import AppKit
import SwiftUI

final class HostedWindowController: NSObject, NSWindowDelegate {

    private var window: NSWindow?
    private let title: String
    private let size: NSSize
    private let minSize: NSSize
    private let isResizable: Bool

    init(title: String, size: NSSize, minSize: NSSize? = nil, isResizable: Bool = true) {
        self.title = title
        self.size = size
        self.minSize = minSize ?? size
        self.isResizable = isResizable
    }

    func show<Content: View>(@ViewBuilder content: () -> Content) {
        if window == nil {
            var styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
            if isResizable {
                styleMask.insert(.resizable)
            }

            let window = NSWindow(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: styleMask,
                backing: .buffered,
                defer: false
            )
            window.title = title
            window.titleVisibility = .visible
            window.titlebarAppearsTransparent = false
            window.backgroundColor = .windowBackgroundColor
            window.isOpaque = true
            window.minSize = minSize
            window.isReleasedWhenClosed = false
            window.center()
            window.delegate = self
            self.window = window
        }

        let hostingView = NSHostingView(rootView: content())
        window?.contentView = hostingView
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        window?.contentView = nil
        window = nil
    }
}

enum AppWindows {

    static let preferences = HostedWindowController(
        title: String(localized: .klippPreferences),
        size: NSSize(width: 580, height: 520),
        minSize: NSSize(width: 540, height: 480)
    )

    static let about = HostedWindowController(
        title: String(localized: .aboutKlipp),
        size: NSSize(width: 300, height: 360),
        isResizable: false
    )
}
