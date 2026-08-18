//
//  PreferencesView.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import AppKit
import SwiftUI

struct PreferencesView: View {

    @ObservedObject var store: KlippStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                preferencesSection(title: String(localized: .general)) {
                    preferencesCard {
                        preferenceRow(
                            title: String(localized: .launchAtLogin),
                            caption: String(localized: .launchAtLoginCaption)
                        ) {
                            Toggle("", isOn: store.binding(
                                get: \.preferences.launchAtLogin,
                                send: { .preferences(.setLaunchAtLogin($0)) }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .tint(.blue)
                            .padding(.trailing, -6)
                        }

                        rowDivider

                        preferenceRow(
                            title: String(localized: .keyboardShortcut),
                            caption: String(localized: .keyboardShortcutCaption)
                        ) {
                            Button {
                                store.send(.preferences(.recordShortcutTapped))
                            } label: {
                                Text(store.state.preferences.isRecordingShortcut
                                    ? String(localized: .pressKeys)
                                    : store.state.preferences.shortcut.displayString)
                                    .frame(width: 104)
                            }
                            .controlSize(.small)
                        }

                        rowDivider

                        preferenceRow(
                            title: String(localized: .defaultPanelView),
                            caption: String(localized: .defaultPanelViewCaption)
                        ) {
                            Picker("", selection: store.binding(
                                get: \.preferences.defaultPanelMode,
                                send: { .preferences(.setDefaultPanelMode($0)) }
                            )) {
                                Text(String(localized: .panelModeCompact)).tag(PanelMode.compact)
                                Text(String(localized: .panelModeFull)).tag(PanelMode.full)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                            .frame(width: 180)
                            .padding(.trailing, -14)
                        }
                    }
                }

                preferencesSection(title: String(localized: .history)) {
                    preferencesCard {
                        preferenceRow(
                            title: String(localized: .keepItemsFor),
                            caption: String(localized: .keepItemsForCaption)
                        ) {
                            Picker("", selection: store.binding(
                                get: \.preferences.retention,
                                send: { .preferences(.setRetention($0)) }
                            )) {
                                ForEach(RetentionPeriod.allCases, id: \.self) { period in
                                    Text(period.displayName).tag(period)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(width: 140)
                            .padding(.trailing, -20)
                        }

                        rowDivider

                        preferenceRow(
                            title: String(localized: .storageUsed),
                            caption: String(localized: .storageUsedCaption)
                        ) {
                            Text(storageText)
                                .font(AppTheme.Fonts.rowCaption)
                                .foregroundStyle(Color.secondaryText)
                        }

                        rowDivider

                        preferenceRow(
                            title: String(localized: .clearAllHistory),
                            caption: String(localized: .permanentlyDeletesEveryStoredItem)
                        ) {
                            Button(role: .destructive) {
                                store.send(.clearHistoryTapped)
                            } label: {
                                Text(String(localized: .clearEllipsis))
                                    .frame(width: 76)
                            }
                            .controlSize(.small)
                        }
                    }
                }

                preferencesSection(title: String(localized: .privacy)) {
                    preferencesCard {
                        preferenceRow(
                            title: String(localized: .ignoredApps),
                            caption: String(localized: .ignoredAppsCaption)
                        ) {
                            Button {
                                store.send(.preferences(.addIgnoredAppTapped))
                            } label: {
                                Text(String(localized: .addEllipsis))
                                    .frame(width: 76)
                            }
                            .controlSize(.small)
                        }

                        if store.state.preferences.ignoredApps.isEmpty {
                            rowDivider
                            emptyIgnoredApps
                        } else {
                            ForEach(store.state.preferences.ignoredApps) { app in
                                rowDivider
                                ignoredAppRow(app)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 24)
        }
        .scrollIndicators(.hidden)
        .background(.ultraThinMaterial)
        .frame(minWidth: 540, idealWidth: 580, minHeight: 480, idealHeight: 520, alignment: .topLeading)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            store.send(.preferences(.refreshLaunchAtLogin))
        }
    }

    private var storageText: String {
        guard let bytes = store.state.preferences.storageBytes else {
            return String(localized: .calculating)
        }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.divider)
            .frame(height: 1)
            .padding(.horizontal, 18)
    }

    private var emptyIgnoredApps: some View {
        Text(String(localized: .noIgnoredApps))
            .font(AppTheme.Fonts.rowCaption)
            .foregroundStyle(Color.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
    }

    private func ignoredAppRow(_ app: IgnoredApp) -> some View {
        HStack(spacing: 10) {
            Image(nsImage: Self.icon(for: app.bundleID))
                .resizable()
                .frame(width: 22, height: 22)

            Text(app.name)
                .font(.system(size: 13))
                .foregroundStyle(Color.primaryText)

            Spacer(minLength: 16)

            Button {
                store.send(.preferences(.removeIgnoredApp(app.bundleID)))
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.secondaryText)
            }
            .buttonStyle(.plain)
            .help(String(localized: .removeFromIgnored))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private static func icon(for bundleID: String) -> NSImage {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil) ?? NSImage()
    }

    private func preferencesSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.primaryText)

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func preferencesCard<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.panelStroke, lineWidth: 1)
                }
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func preferenceRow<Control: View>(
        title: String,
        caption: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.primaryText)

                Text(caption)
                    .font(AppTheme.Fonts.rowCaption)
                    .foregroundStyle(Color.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 16)

            control()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
