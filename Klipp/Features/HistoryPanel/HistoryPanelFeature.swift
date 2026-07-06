//
//  HistoryPanelFeature.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import Foundation

enum HistoryPanelFeature {

    struct State: Equatable {
        var isVisible = false
        var searchText = ""
        var typeFilter: ClipItemType?
        var selectedID: String?
        var mode = AppDefaults.panelMode
    }

    enum Action {
        case showRequested
        case close
        case resignedKey
        case searchTextChanged(String)
        case typeFilterChanged(ClipItemType?)
        case moveSelection(Int)
        case itemClicked(String)
        case activateSelected
        case activateIndex(Int)
        case deleteItem(String)
        case toggleMode
    }

    static func panelSize(for state: State) -> CGSize {
        switch state.mode {
        case .compact: return CGSize(width: 520, height: 480)
        case .full: return CGSize(width: 700, height: 480)
        }
    }

    static func visibleItems(_ state: KlippFeature.State) -> [ClipItem] {
        let query = state.panel.searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        var filtered = state.items

        if let typeFilter = state.panel.typeFilter {
            filtered = filtered.filter { $0.type == typeFilter }
        }

        if !query.isEmpty {
            filtered = filtered.filter { ($0.textContent ?? "").lowercased().contains(query) }
        }

        return filtered
    }

    static func selectedItem(_ state: KlippFeature.State) -> ClipItem? {
        guard let id = state.panel.selectedID else { return nil }
        return state.items.first { $0.id == id }
    }

    static func reduce(into state: inout KlippFeature.State, action: Action) -> Effect<KlippFeature.Action> {
        switch action {

        case .showRequested:
            state.panel.searchText = ""
            state.panel.typeFilter = nil
            state.panel.isVisible = true
            state.panel.selectedID = visibleItems(state).first?.id
            return .fireAndForget {
                PanelController.shared.show()
            }

        case .close, .resignedKey:
            state.panel.isVisible = false
            return .fireAndForget {
                PanelController.shared.hide()
            }

        case .searchTextChanged(let text):
            state.panel.searchText = text
            state.panel.selectedID = visibleItems(state).first?.id
            return .none

        case .typeFilterChanged(let filter):
            state.panel.typeFilter = filter
            state.panel.selectedID = visibleItems(state).first?.id
            return .none

        case .moveSelection(let delta):
            let items = visibleItems(state)
            guard !items.isEmpty else { return .none }

            let currentIndex = items.firstIndex { $0.id == state.panel.selectedID } ?? 0
            let newIndex = min(max(currentIndex + delta, 0), items.count - 1)
            state.panel.selectedID = items[newIndex].id
            return .none

        case .itemClicked(let id):
            return activate(id: id, state: &state)

        case .activateSelected:
            guard let id = state.panel.selectedID else { return .none }
            return activate(id: id, state: &state)

        case .activateIndex(let index):
            let items = visibleItems(state)
            guard items.indices.contains(index) else { return .none }
            return activate(id: items[index].id, state: &state)

        case .deleteItem(let id):
            let items = visibleItems(state)
            if state.panel.selectedID == id,
               let index = items.firstIndex(where: { $0.id == id }) {
                let remaining = items.filter { $0.id != id }
                let nextIndex = min(index, remaining.count - 1)
                state.panel.selectedID = nextIndex >= 0 ? remaining[nextIndex].id : nil
            }
            return .fireAndForget {
                AppEnvironment.shared.deleteItem(id: id)
            }

        case .toggleMode:
            state.panel.mode = state.panel.mode.toggled
            let mode = state.panel.mode
            return .fireAndForget {
                AppDefaults.panelMode = mode
                PanelController.shared.applySize()
            }
        }
    }

    private static func activate(id: String, state: inout KlippFeature.State) -> Effect<KlippFeature.Action> {
        state.panel.isVisible = false
        return .fireAndForget {
            let environment = AppEnvironment.shared
            PanelController.shared.hide()

            guard let item = environment.clipStore.fetchItem(id: id) else { return }
            environment.clipboardWriter.write(item)
            environment.clipStore.touch(id: id)
        }
    }
}
