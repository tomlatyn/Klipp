//
//  KlippApp.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import AppKit
import SwiftUI

@main
struct KlippApp: App {

    @NSApplicationDelegateAdaptor(KlippAppDelegate.self) private var appDelegate
    @StateObject private var store: KlippStore

    init() {
        AppDefaults.register()

        let store = KlippStore(
            initialState: KlippFeature.State(),
            reducer: KlippFeature.reducer()
        )
        _store = StateObject(wrappedValue: store)
        appDelegate.store = store

        AppEnvironment.shared.bootstrap(store: store)

        DispatchQueue.main.async {
            store.send(.appLaunched)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            Button {
                store.send(.showPanelTapped)
            } label: {
                Text(String(localized: .showClipboardHistory))
            }
            .keyboardShortcut(store.state.preferences.shortcut.keyboardShortcut)

            Divider()

            Button {
                store.send(.togglePauseTapped)
            } label: {
                Text(store.state.isPaused
                    ? String(localized: .resumeKlipp)
                    : String(localized: .pauseKlipp))
            }

            Button {
                store.send(.clearHistoryTapped)
            } label: {
                Text(String(localized: .clearHistoryEllipsis))
            }

            Divider()

            Button {
                store.send(.preferencesTapped)
            } label: {
                Text(String(localized: .menuPreferences))
            }
            .keyboardShortcut(",", modifiers: [.command])

            Button {
                store.send(.aboutTapped)
            } label: {
                Text(String(localized: .aboutKlipp))
            }

            Button {
                store.send(.quitTapped)
            } label: {
                Text(String(localized: .quitKlipp))
            }
            .keyboardShortcut("q", modifiers: [.command])
        } label: {
            Image(systemName: store.state.isPaused ? "paperclip.badge.ellipsis" : "paperclip")
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(String(localized: .menuPreferences)) {
                    store.send(.preferencesTapped)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
    }
}

final class KlippAppDelegate: NSObject, NSApplicationDelegate {

    weak var store: KlippStore?

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            store?.send(.showPanelTapped)
        }
        return true
    }
}
