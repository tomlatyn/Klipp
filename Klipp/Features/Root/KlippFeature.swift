//
//  KlippFeature.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import AppKit
import Foundation

typealias KlippStore = Store<KlippFeature.State, KlippFeature.Action>

enum KlippFeature {

    struct State: Equatable {
        var items: [ClipItem] = []
        var isPaused = AppDefaults.isMonitoringPaused
        var retention = AppDefaults.retentionPeriod
        var panel = HistoryPanelFeature.State()
        var preferences = PreferencesFeature.State()
    }

    enum Action {
        case appLaunched
        case itemsChanged([ClipItem])
        case clipboardCaptured(ClipboardCapture)
        case hotKeyPressed
        case showPanelTapped
        case togglePauseTapped
        case clearHistoryTapped
        case clearHistoryConfirmed
        case preferencesTapped
        case aboutTapped
        case quitTapped
        case retentionTick
        case panel(HistoryPanelFeature.Action)
        case preferences(PreferencesFeature.Action)
    }

    static func reducer() -> (inout State, Action) -> Effect<Action> {
        { state, action in
            switch action {

            case .appLaunched:
                return .fireAndForget {
                    AppEnvironment.shared.startCoreServices()
                }

            case .itemsChanged(let items):
                state.items = items
                if state.panel.isVisible {
                    let visible = HistoryPanelFeature.visibleItems(state)
                    if state.panel.selectedID == nil || !visible.contains(where: { $0.id == state.panel.selectedID }) {
                        state.panel.selectedID = visible.first?.id
                    }
                }
                return .none

            case .clipboardCaptured(let capture):
                guard !state.isPaused else { return .none }
                return .fireAndForget {
                    AppEnvironment.shared.insertCapture(capture)
                }

            case .hotKeyPressed:
                if state.panel.isVisible {
                    return .send(.panel(.close))
                }
                return .send(.panel(.showRequested))

            case .showPanelTapped:
                return .send(.panel(.showRequested))

            case .togglePauseTapped:
                state.isPaused.toggle()
                let isPaused = state.isPaused
                return .fireAndForget {
                    AppDefaults.isMonitoringPaused = isPaused
                    AppEnvironment.shared.monitor.isPaused = isPaused
                }

            case .clearHistoryTapped:
                return confirmClearHistory(fromPanel: state.panel.isVisible)

            case .clearHistoryConfirmed:
                return .fireAndForget {
                    AppEnvironment.shared.clearHistory()
                }

            case .preferencesTapped:
                state.preferences.refreshFromSystem()
                return .merge(
                    .fireAndForget {
                        guard let store = AppEnvironment.shared.store else { return }
                        AppWindows.preferences.show {
                            PreferencesView(store: store)
                        }
                    },
                    Effect { send in
                        AppEnvironment.shared.computeStorageSize { bytes in
                            send(.preferences(.storageSizeComputed(bytes)))
                        }
                    }
                )

            case .aboutTapped:
                return .fireAndForget {
                    AppWindows.about.show {
                        AboutView()
                    }
                }

            case .quitTapped:
                return .fireAndForget {
                    NSApp.terminate(nil)
                }

            case .retentionTick:
                let retention = state.retention
                return .fireAndForget {
                    AppEnvironment.shared.cleanupExpired(retention: retention)
                }

            case .panel(let panelAction):
                return HistoryPanelFeature.reduce(into: &state, action: panelAction)

            case .preferences(let preferencesAction):
                return PreferencesFeature.reduce(into: &state, action: preferencesAction)
            }
        }
    }

    private static func confirmClearHistory(fromPanel: Bool) -> Effect<Action> {
        Effect { send in
            DispatchQueue.main.async {
                if fromPanel,
                   PanelController.shared.confirmClearHistory(completion: { confirmed in
                       if confirmed {
                           send(.clearHistoryConfirmed)
                       }
                   }) {
                    return
                }

                let alert = NSAlert()
                alert.messageText = String(localized: .clearClipboardHistoryQuestion)
                alert.informativeText = String(localized: .clearClipboardHistoryMessage)
                alert.alertStyle = .warning
                alert.addButton(withTitle: String(localized: .clearHistory))
                alert.addButton(withTitle: String(localized: .cancel))

                if alert.runModal() == .alertFirstButtonReturn {
                    send(.clearHistoryConfirmed)
                }
            }
        }
    }
}
