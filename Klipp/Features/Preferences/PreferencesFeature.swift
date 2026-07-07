//
//  PreferencesFeature.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import Foundation

enum PreferencesFeature {

    struct State: Equatable {
        var launchAtLogin = false
        var shortcut = AppDefaults.hotKeyShortcut
        var isRecordingShortcut = false
        var defaultPanelMode = AppDefaults.panelMode
        var retention = AppDefaults.retentionPeriod
        var ignoredApps = AppDefaults.ignoredApps
        var storageBytes: Int?

        mutating func refreshFromSystem() {
            launchAtLogin = LaunchAtLoginService.isEnabled
            shortcut = AppDefaults.hotKeyShortcut
            defaultPanelMode = AppDefaults.panelMode
            retention = AppDefaults.retentionPeriod
            ignoredApps = AppDefaults.ignoredApps
            isRecordingShortcut = false
            storageBytes = nil
        }
    }

    enum Action {
        case setLaunchAtLogin(Bool)
        case launchAtLoginUpdateFailed(previousValue: Bool)
        case recordShortcutTapped
        case shortcutCaptured(KeyShortcut)
        case shortcutRegistrationFailed(previousValue: KeyShortcut)
        case recordingCancelled
        case setDefaultPanelMode(PanelMode)
        case setRetention(RetentionPeriod)
        case addIgnoredAppTapped
        case ignoredAppAdded(IgnoredApp)
        case removeIgnoredApp(String)
        case storageSizeComputed(Int)
    }

    static func reduce(into state: inout KlippFeature.State, action: Action) -> Effect<KlippFeature.Action> {
        switch action {

        case .setLaunchAtLogin(let enabled):
            let previousValue = state.preferences.launchAtLogin
            state.preferences.launchAtLogin = enabled
            return Effect { send in
                do {
                    try LaunchAtLoginService.setEnabled(enabled)
                } catch {
                    send(.preferences(.launchAtLoginUpdateFailed(previousValue: previousValue)))
                }
            }

        case .launchAtLoginUpdateFailed(let previousValue):
            state.preferences.launchAtLogin = previousValue
            return .none

        case .recordShortcutTapped:
            guard !state.preferences.isRecordingShortcut else { return .none }
            state.preferences.isRecordingShortcut = true
            return Effect { send in
                ShortcutRecorder.shared.begin { shortcut in
                    if let shortcut {
                        send(.preferences(.shortcutCaptured(shortcut)))
                    } else {
                        send(.preferences(.recordingCancelled))
                    }
                }
            }

        case .shortcutCaptured(let shortcut):
            let previousValue = state.preferences.shortcut
            state.preferences.isRecordingShortcut = false
            state.preferences.shortcut = shortcut
            return Effect { send in
                if AppEnvironment.shared.hotKey.register(shortcut) {
                    AppDefaults.hotKeyShortcut = shortcut
                } else {
                    send(.preferences(.shortcutRegistrationFailed(previousValue: previousValue)))
                }
            }

        case .shortcutRegistrationFailed(let previousValue):
            state.preferences.shortcut = previousValue
            return .none

        case .recordingCancelled:
            state.preferences.isRecordingShortcut = false
            return .none

        case .setDefaultPanelMode(let mode):
            state.preferences.defaultPanelMode = mode
            state.panel.mode = mode
            return .fireAndForget {
                AppDefaults.panelMode = mode
            }

        case .setRetention(let retention):
            state.preferences.retention = retention
            state.retention = retention
            return .fireAndForget {
                AppDefaults.retentionPeriod = retention
                AppEnvironment.shared.cleanupExpired(retention: retention)
            }

        case .addIgnoredAppTapped:
            return Effect { send in
                if let app = AppPicker.pickApplication() {
                    send(.preferences(.ignoredAppAdded(app)))
                }
            }

        case .ignoredAppAdded(let app):
            guard !state.preferences.ignoredApps.contains(where: { $0.bundleID == app.bundleID }) else {
                return .none
            }
            state.preferences.ignoredApps.append(app)
            state.preferences.ignoredApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            let ignoredApps = state.preferences.ignoredApps
            return .fireAndForget {
                AppDefaults.ignoredApps = ignoredApps
                AppEnvironment.shared.monitor.ignoredBundleIDs = Set(ignoredApps.map(\.bundleID))
            }

        case .removeIgnoredApp(let bundleID):
            state.preferences.ignoredApps.removeAll { $0.bundleID == bundleID }
            let ignoredApps = state.preferences.ignoredApps
            return .fireAndForget {
                AppDefaults.ignoredApps = ignoredApps
                AppEnvironment.shared.monitor.ignoredBundleIDs = Set(ignoredApps.map(\.bundleID))
            }

        case .storageSizeComputed(let bytes):
            state.preferences.storageBytes = bytes
            return .none
        }
    }
}
