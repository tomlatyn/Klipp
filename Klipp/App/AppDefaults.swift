//
//  AppDefaults.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import Foundation

enum AppDefaults {

    enum Keys {
        static let retentionPeriod = "retentionPeriod"
        static let panelMode = "panelMode"
        static let hotKeyKeyCode = "hotKeyKeyCode"
        static let hotKeyModifiers = "hotKeyModifiers"
        static let isMonitoringPaused = "isMonitoringPaused"
        static let hasRegisteredLaunchAtLogin = "hasRegisteredLaunchAtLogin"
        static let ignoredApps = "ignoredApps"
    }

    static func register() {
        UserDefaults.standard.register(defaults: [
            Keys.retentionPeriod: RetentionPeriod.sevenDays.rawValue,
            Keys.panelMode: PanelMode.compact.rawValue,
            Keys.hotKeyKeyCode: Int(KeyShortcut.defaultShortcut.keyCode),
            Keys.hotKeyModifiers: Int(KeyShortcut.defaultShortcut.carbonModifiers),
            Keys.isMonitoringPaused: false,
            Keys.hasRegisteredLaunchAtLogin: false
        ])
    }

    static var retentionPeriod: RetentionPeriod {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.retentionPeriod) ?? ""
            return RetentionPeriod(rawValue: raw) ?? .sevenDays
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.retentionPeriod)
        }
    }

    static var panelMode: PanelMode {
        get {
            let raw = UserDefaults.standard.string(forKey: Keys.panelMode) ?? ""
            return PanelMode(rawValue: raw) ?? .compact
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Keys.panelMode)
        }
    }

    static var hotKeyShortcut: KeyShortcut {
        get {
            KeyShortcut(
                keyCode: UInt32(UserDefaults.standard.integer(forKey: Keys.hotKeyKeyCode)),
                carbonModifiers: UInt32(UserDefaults.standard.integer(forKey: Keys.hotKeyModifiers))
            )
        }
        set {
            UserDefaults.standard.set(Int(newValue.keyCode), forKey: Keys.hotKeyKeyCode)
            UserDefaults.standard.set(Int(newValue.carbonModifiers), forKey: Keys.hotKeyModifiers)
        }
    }

    static var isMonitoringPaused: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.isMonitoringPaused) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.isMonitoringPaused) }
    }

    static var hasRegisteredLaunchAtLogin: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasRegisteredLaunchAtLogin) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasRegisteredLaunchAtLogin) }
    }

    static var ignoredApps: [IgnoredApp] {
        get {
            guard let data = UserDefaults.standard.data(forKey: Keys.ignoredApps),
                  let apps = try? JSONDecoder().decode([IgnoredApp].self, from: data) else {
                return []
            }
            return apps
        }
        set {
            let data = try? JSONEncoder().encode(newValue)
            UserDefaults.standard.set(data, forKey: Keys.ignoredApps)
        }
    }
}
