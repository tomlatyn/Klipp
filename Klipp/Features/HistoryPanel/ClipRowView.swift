//
//  ClipRowView.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import SwiftUI

struct ClipRowView: View {

    let item: ClipItem
    let isSelected: Bool
    var shortcutIndex: Int?
    var onTap: () -> Void
    var onDelete: () -> Void
    var onTogglePin: () -> Void
    var onCopyPlain: () -> Void

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            leadingVisual

            Text(item.previewLine)
                .font(AppTheme.Fonts.rowTitle)
                .foregroundStyle(Color.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: AppTheme.Spacing.small)

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.secondaryText)
            }

            if let shortcutIndex {
                Text("⌘\(shortcutIndex)")
                    .font(AppTheme.Fonts.shortcutHint)
                    .foregroundStyle(Color.tertiaryText)
            }

            Text(Self.relativeFormatter.localizedString(for: item.createdAt, relativeTo: Date()))
                .font(AppTheme.Fonts.metadata)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.vertical, AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.row, style: .continuous)
                .fill(isSelected ? Color.selectionTint : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button(action: onTogglePin) {
                Label(
                    item.isPinned ? String(localized: .unpin) : String(localized: .pin),
                    systemImage: item.isPinned ? "pin.slash" : "pin"
                )
            }
            if item.rtfData != nil {
                Button(action: onCopyPlain) {
                    Label(String(localized: .copyAsPlainText), systemImage: "textformat")
                }
            }
            Button(String(localized: .delete), role: .destructive, action: onDelete)
        }
    }

    @ViewBuilder
    private var leadingVisual: some View {
        if item.type == .image,
           let filename = item.thumbnailFilename,
           let thumbnail = AppEnvironment.shared.imageStore.thumbnail(named: filename) {
            Image(nsImage: thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: 26, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.thumbnail, style: .continuous))
        } else {
            Image(systemName: item.type.symbolName)
                .font(.system(size: 12))
                .foregroundStyle(Color.secondaryText)
                .frame(width: 26, height: 26)
        }
    }
}
