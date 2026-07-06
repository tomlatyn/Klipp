//
//  PreferencesView.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import SwiftUI

struct PreferencesView: View {

    @ObservedObject var store: KlippStore

    var body: some View {
        Form {
            Section {
                Toggle(isOn: store.binding(
                    get: \.preferences.launchAtLogin,
                    send: { .preferences(.setLaunchAtLogin($0)) }
                )) {
                    Text(String(localized: .launchAtLogin))
                }

                LabeledContent {
                    Button {
                        store.send(.preferences(.recordShortcutTapped))
                    } label: {
                        Text(store.state.preferences.isRecordingShortcut
                            ? String(localized: .pressKeys)
                            : store.state.preferences.shortcut.displayString)
                            .frame(minWidth: 88)
                    }
                    .controlSize(.small)
                } label: {
                    Text(String(localized: .keyboardShortcut))
                }

                LabeledContent {
                    Picker("", selection: store.binding(
                        get: \.preferences.defaultPanelMode,
                        send: { .preferences(.setDefaultPanelMode($0)) }
                    )) {
                        Text(String(localized: .panelModeCompact)).tag(PanelMode.compact)
                        Text(String(localized: .panelModeFull)).tag(PanelMode.full)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(width: 150)
                } label: {
                    Text(String(localized: .defaultPanelView))
                }
            } header: {
                Text(String(localized: .general))
            }

            Section {
                LabeledContent {
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
                    .fixedSize()
                } label: {
                    Text(String(localized: .keepItemsFor))
                }

                LabeledContent {
                    Text(storageText)
                        .foregroundStyle(.secondary)
                } label: {
                    Text(String(localized: .storageUsed))
                }

                LabeledContent {
                    Button(role: .destructive) {
                        store.send(.clearHistoryTapped)
                    } label: {
                        Text(String(localized: .clearEllipsis))
                    }
                    .controlSize(.small)
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(String(localized: .clearAllHistory))

                        Text(String(localized: .permanentlyDeletesEveryStoredItem))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } header: {
                Text(String(localized: .history))
            }
        }
        .formStyle(.grouped)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
        .frame(minWidth: 380, idealWidth: 400, minHeight: 260, idealHeight: 280)
    }

    private var storageText: String {
        guard let bytes = store.state.preferences.storageBytes else {
            return String(localized: .calculating)
        }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
