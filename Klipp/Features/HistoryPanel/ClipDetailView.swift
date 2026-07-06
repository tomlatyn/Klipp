//
//  ClipDetailView.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import SwiftUI

struct ClipDetailView: View {

    let item: ClipItem?

    var body: some View {
        if let item {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                preview(for: item)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Rectangle()
                    .fill(Color.divider)
                    .frame(height: 1)

                metadata(for: item)
            }
            .padding(AppTheme.Spacing.large)
        } else {
            VStack(spacing: AppTheme.Spacing.small) {
                Image(systemName: "cursorarrow.rays")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.tertiaryText)

                Text(String(localized: .selectItemToPreview))
                    .font(AppTheme.Fonts.rowCaption)
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func preview(for item: ClipItem) -> some View {
        switch item.type {

        case .text:
            ScrollView {
                Text(item.textContent ?? "")
                    .font(AppTheme.Fonts.rowCaption)
                    .foregroundStyle(Color.primaryText)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .link:
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                if let text = item.textContent, let url = URL(string: text) {
                    Link(text, destination: url)
                        .font(AppTheme.Fonts.rowCaption)
                        .lineLimit(6)
                } else {
                    Text(item.textContent ?? "")
                        .font(AppTheme.Fonts.rowCaption)
                        .foregroundStyle(Color.primaryText)
                }
            }

        case .image:
            if let filename = item.imageFilename,
               let image = AppEnvironment.shared.imageStore.image(named: filename) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.thumbnail, style: .continuous))
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.tertiaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .file:
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    ForEach(item.fileURLs ?? [], id: \.self) { path in
                        HStack(spacing: AppTheme.Spacing.small) {
                            Image(systemName: "doc")
                                .font(.system(size: 11))
                                .foregroundStyle(Color.secondaryText)

                            Text(URL(fileURLWithPath: path).lastPathComponent)
                                .font(AppTheme.Fonts.rowCaption)
                                .foregroundStyle(Color.primaryText)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func metadata(for item: ClipItem) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.tiny) {
            metadataRow(label: String(localized: .metadataType), value: item.type.displayName)
            metadataRow(label: String(localized: .metadataSize), value: item.formattedByteSize)

            if let width = item.pixelWidth, let height = item.pixelHeight {
                metadataRow(label: String(localized: .metadataDimensions), value: String(localized: .dimensionsFormat(width, height)))
            }

            if let count = item.characterCount {
                metadataRow(label: String(localized: .metadataCharacters), value: "\(count)")
            }

            if let files = item.fileURLs, files.count > 1 {
                metadataRow(label: String(localized: .metadataFiles), value: "\(files.count)")
            }

            if let sourceName = item.sourceAppName {
                metadataRow(label: String(localized: .metadataSource), value: sourceName)
            }

            metadataRow(
                label: String(localized: .metadataCopied),
                value: item.createdAt.formatted(date: .abbreviated, time: .shortened)
            )
        }
    }

    private func metadataRow(label: String, value: String) -> some View {
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
