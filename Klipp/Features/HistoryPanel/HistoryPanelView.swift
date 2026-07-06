//
//  HistoryPanelView.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import SwiftUI

struct HistoryPanelView: View {

    @ObservedObject var store: KlippStore
    @FocusState private var isSearchFocused: Bool

    private var visibleItems: [ClipItem] {
        HistoryPanelFeature.visibleItems(store.state)
    }

    private var selectedItem: ClipItem? {
        HistoryPanelFeature.selectedItem(store.state)
    }

    var body: some View {
        let size = HistoryPanelFeature.panelSize(for: store.state.panel)

        VStack(spacing: 0) {
            header
            filterBar

            Rectangle()
                .fill(Color.divider)
                .frame(height: 1)

            if visibleItems.isEmpty {
                emptyState
            } else {
                content
            }

            Rectangle()
                .fill(Color.divider)
                .frame(height: 1)

            footer
        }
        .frame(width: size.width, height: size.height)
        .glassSurface()
        .onAppear {
            DispatchQueue.main.async {
                isSearchFocused = true
            }
        }
    }

    private var header: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(Color.secondaryText)

            TextField(String(localized: .searchHistory), text: store.binding(
                get: \.panel.searchText,
                send: { .panel(.searchTextChanged($0)) }
            ))
            .textFieldStyle(.plain)
            .font(AppTheme.Fonts.rowTitle)
            .focused($isSearchFocused)

            Button {
                store.send(.panel(.toggleMode))
            } label: {
                Image(systemName: store.state.panel.mode == .compact
                    ? "sidebar.trailing"
                    : "sidebar.leading")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.secondaryText)
            }
            .buttonStyle(.plain)
            .help(String(localized: .togglePreviewPaneHelp))
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.vertical, AppTheme.Spacing.medium)
    }

    private var filterBar: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            filterChip(nil, label: String(localized: .all))

            ForEach(ClipItemType.allCases, id: \.self) { type in
                filterChip(type, label: type.displayName)
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.bottom, AppTheme.Spacing.medium)
    }

    private func filterChip(_ type: ClipItemType?, label: String) -> some View {
        let isSelected = store.state.panel.typeFilter == type

        return Button {
            store.send(.panel(.typeFilterChanged(type)))
        } label: {
            Text(label)
                .font(AppTheme.Fonts.rowCaption)
                .foregroundStyle(isSelected ? Color.primaryText : Color.secondaryText)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, AppTheme.Spacing.tiny)
                .background(
                    Capsule(style: .continuous)
                        .fill(isSelected ? Color.selectionTint : Color.clear)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : Color.divider, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        HStack(spacing: 0) {
            list
                .frame(maxWidth: .infinity)

            if store.state.panel.mode == .full {
                Rectangle()
                    .fill(Color.divider)
                    .frame(width: 1)

                ClipDetailView(item: selectedItem)
                    .frame(width: 290)
            }
        }
    }

    private var list: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(Array(visibleItems.enumerated()), id: \.element.id) { index, item in
                        ClipRowView(
                            item: item,
                            isSelected: item.id == store.state.panel.selectedID,
                            shortcutIndex: index < 9 ? index + 1 : nil,
                            onTap: { store.send(.panel(.itemClicked(item.id))) },
                            onDelete: { store.send(.panel(.deleteItem(item.id))) }
                        )
                        .id(item.id)
                    }
                }
                .padding(AppTheme.Spacing.small)
            }
            .onChange(of: store.state.panel.selectedID) { _, newValue in
                if let newValue {
                    proxy.scrollTo(newValue)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "clipboard")
                .font(.system(size: 28))
                .foregroundStyle(Color.tertiaryText)

            Text(store.state.panel.searchText.isEmpty && store.state.panel.typeFilter == nil
                ? String(localized: .nothingCopiedYet)
                : String(localized: .noMatches))
                .font(AppTheme.Fonts.rowCaption)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: AppTheme.Spacing.large) {
            hint(symbol: "↑↓", label: String(localized: .navigate))
            hint(symbol: "↩", label: String(localized: .copy))
            hint(symbol: "⇥", label: String(localized: .view))
            hint(symbol: "⎋", label: String(localized: .close))

            Spacer()

            Text(String(localized: .itemsCountFormat(visibleItems.count)))
                .font(AppTheme.Fonts.metadata)
                .foregroundStyle(Color.tertiaryText)

            Button(role: .destructive) {
                store.send(.clearHistoryTapped)
            } label: {
                Text(String(localized: .clearHistory))
                    .font(AppTheme.Fonts.metadata)
                    .foregroundStyle(Color.secondaryText)
            }
            .buttonStyle(.plain)
            .help(String(localized: .clearAllHistory))
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.vertical, AppTheme.Spacing.small)
    }

    private func hint(symbol: String, label: String) -> some View {
        HStack(spacing: AppTheme.Spacing.tiny) {
            Text(symbol)
                .font(AppTheme.Fonts.shortcutHint)
                .foregroundStyle(Color.secondaryText)

            Text(label)
                .font(AppTheme.Fonts.metadata)
                .foregroundStyle(Color.tertiaryText)
        }
    }
}
