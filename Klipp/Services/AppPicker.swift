//
//  AppPicker.swift
//  Klipp
//
//  Created by Tomáš Latýn on 07.07.2026.
//

import AppKit
import UniformTypeIdentifiers

enum AppPicker {

    static func pickApplication() -> IgnoredApp? {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.prompt = String(localized: .choose)
        panel.message = String(localized: .chooseAppToIgnore)

        NSApp.activate(ignoringOtherApps: true)

        guard panel.runModal() == .OK,
              let url = panel.url,
              let bundleID = Bundle(url: url)?.bundleIdentifier else {
            return nil
        }

        let name = FileManager.default.displayName(atPath: url.path)
            .replacingOccurrences(of: ".app", with: "")

        return IgnoredApp(bundleID: bundleID, name: name)
    }
}
