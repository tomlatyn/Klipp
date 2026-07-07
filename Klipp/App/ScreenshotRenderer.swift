//
//  ScreenshotRenderer.swift
//  Klipp
//
//  Created by Tomáš Latýn on 07.07.2026.
//

#if DEBUG

import AppKit
import SwiftUI

enum ScreenshotRenderer {

    static func renderIfRequested() {
        let arguments = CommandLine.arguments
        guard let flagIndex = arguments.firstIndex(of: "--render-screenshot"),
              flagIndex + 1 < arguments.count else {
            return
        }

        let outputURL = URL(fileURLWithPath: arguments[flagIndex + 1])
        MainActor.assumeIsolated {
            render(to: outputURL)
        }
        exit(0)
    }

    @MainActor
    private static func render(to url: URL) {
        NSApp?.appearance = NSAppearance(named: .darkAqua)

        let items = demoItems()
        let selectedID = items.first { $0.type == .text }?.id
        let content = ScreenshotPanel(items: items, selectedID: selectedID)
            .padding(56)
            .background(backdrop)
            .environment(\.colorScheme, .dark)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2

        guard let cgImage = renderer.cgImage else {
            fail("failed to render image")
        }

        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            fail("failed to encode PNG")
        }

        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: url)
            print("Screenshot written to \(url.path)")
        } catch {
            fail("failed to write \(url.path): \(error)")
        }
    }

    private static var backdrop: some View {
        LinearGradient(
            colors: [Color(nsColor: .underPageBackgroundColor), Color(nsColor: .windowBackgroundColor)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private static func fail(_ message: String) -> Never {
        FileHandle.standardError.write(Data("ScreenshotRenderer: \(message)\n".utf8))
        exit(1)
    }

    private static func demoItems() -> [ClipItem] {
        [
            item(.link, "https://github.com/tomlatyn/Klipp", minutesAgo: 2, source: "Safari", pinned: true),
            item(.text, "func fibonacci(_ n: Int) -> Int {\n    n < 2 ? n : fibonacci(n - 1) + fibonacci(n - 2)\n}", minutesAgo: 9, source: "Xcode"),
            item(.link, "https://developer.apple.com/documentation/swiftui", minutesAgo: 17, source: "Safari"),
            item(.text, "Meeting moved to 3:00 PM — conference room B", minutesAgo: 34, source: "Notes"),
            item(.text, "#4A90D2", minutesAgo: 58, source: "Figma"),
            item(.text, "git commit -m \"Refine panel layout\"", minutesAgo: 122, source: "Terminal"),
            item(.text, "tom@example.com", minutesAgo: 180, source: "Mail"),
            item(.text, "{ \"status\": \"ok\", \"count\": 42 }", minutesAgo: 305, source: "Terminal")
        ]
    }

    private static func item(
        _ type: ClipItemType,
        _ text: String,
        minutesAgo: Int,
        source: String,
        pinned: Bool = false
    ) -> ClipItem {
        ClipItem(
            id: UUID().uuidString,
            type: type,
            contentHash: text,
            textContent: text,
            rtfData: nil,
            imageFilename: nil,
            thumbnailFilename: nil,
            fileURLs: nil,
            byteSize: text.utf8.count,
            pixelWidth: nil,
            pixelHeight: nil,
            characterCount: text.count,
            sourceAppBundleID: nil,
            sourceAppName: source,
            createdAt: Date().addingTimeInterval(TimeInterval(-minutesAgo * 60)),
            lastUsedAt: nil,
            isPinned: pinned
        )
    }
}

private struct ScreenshotPanel: View {

    let items: [ClipItem]
    let selectedID: String?

    private var selectedItem: ClipItem? {
        items.first { $0.id == selectedID }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            filterBar

            divider

            HStack(spacing: 0) {
                list
                    .frame(maxWidth: .infinity)

                divider
                    .frame(width: 1)

                ScreenshotDetail(item: selectedItem)
                    .frame(width: 290)
            }

            divider

            footer
        }
        .frame(width: 700, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.panel, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.panel, style: .continuous)
                .strokeBorder(Color.panelStroke, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.18), radius: 24, y: 12)
    }

    private var divider: some View {
        Rectangle().fill(Color.divider).frame(height: 1)
    }

    private var header: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(Color.secondaryText)

            Text(String(localized: .searchHistory))
                .font(AppTheme.Fonts.rowTitle)
                .foregroundStyle(Color.tertiaryText)

            Spacer()

            Image(systemName: "sidebar.leading")
                .font(.system(size: 12))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.vertical, AppTheme.Spacing.medium)
    }

    private var filterBar: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            chip(String(localized: .all), selected: true)

            ForEach(ClipItemType.allCases, id: \.self) { type in
                chip(type.displayName, selected: false)
            }

            Spacer()
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.bottom, AppTheme.Spacing.medium)
    }

    private func chip(_ label: String, selected: Bool) -> some View {
        Text(label)
            .font(AppTheme.Fonts.rowCaption)
            .foregroundStyle(selected ? Color.primaryText : Color.secondaryText)
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.vertical, AppTheme.Spacing.tiny)
            .background(
                Capsule(style: .continuous)
                    .fill(selected ? Color.selectionTint : Color.clear)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(selected ? Color.clear : Color.divider, lineWidth: 1)
            )
    }

    private var list: some View {
        VStack(spacing: 2) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                ClipRowView(
                    item: item,
                    isSelected: item.id == selectedID,
                    shortcutIndex: index < 9 ? index + 1 : nil,
                    onTap: {},
                    onDelete: {},
                    onTogglePin: {},
                    onCopyPlain: {}
                )
            }
            Spacer(minLength: 0)
        }
        .padding(AppTheme.Spacing.small)
    }

    private var footer: some View {
        HStack(spacing: AppTheme.Spacing.large) {
            hint("↑↓", String(localized: .navigate))
            hint("↩", String(localized: .copy))
            hint("⌥↩", String(localized: .plain))
            hint("⌘P", String(localized: .pin))
            hint("⇥", String(localized: .view))
            hint("⎋", String(localized: .close))

            Spacer()

            Text(String(localized: .itemsCountFormat(items.count)))
                .font(AppTheme.Fonts.metadata)
                .foregroundStyle(Color.tertiaryText)

            Text(String(localized: .clearHistory))
                .font(AppTheme.Fonts.metadata)
                .foregroundStyle(Color.secondaryText)
        }
        .padding(.horizontal, AppTheme.Spacing.large)
        .padding(.vertical, AppTheme.Spacing.small)
    }

    private func hint(_ symbol: String, _ label: String) -> some View {
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

private struct ScreenshotDetail: View {

    let item: ClipItem?

    var body: some View {
        if let item {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                Text(item.textContent ?? "")
                    .font(AppTheme.Fonts.rowCaption)
                    .foregroundStyle(Color.primaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1)

                metadata(for: item)
            }
            .padding(AppTheme.Spacing.large)
        }
    }

    private func metadata(for item: ClipItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            row(String(localized: .metadataType), item.type.displayName)
            row(String(localized: .metadataSize), item.formattedByteSize)

            if let count = item.characterCount {
                row(String(localized: .metadataCharacters), "\(count)")
            }

            if let source = item.sourceAppName {
                row(String(localized: .metadataSource), source)
            }

            row(
                String(localized: .metadataCopied),
                item.createdAt.formatted(date: .abbreviated, time: .shortened)
            )
        }
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.Spacing.small) {
            Text(label)
                .font(AppTheme.Fonts.metadata)
                .foregroundStyle(Color.tertiaryText)
                .frame(width: 72, alignment: .leading)

            Text(value)
                .font(AppTheme.Fonts.metadata)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

#endif
