//
//  ClipItem.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import Foundation

enum ClipItemType: String, Codable, CaseIterable, Equatable {
    case text
    case link
    case image
    case file

    var symbolName: String {
        switch self {
        case .text: return "doc.on.doc"
        case .link: return "link"
        case .image: return "photo"
        case .file: return "doc"
        }
    }

    var displayName: String {
        switch self {
        case .text: return String(localized: .clipTypeText)
        case .link: return String(localized: .clipTypeLink)
        case .image: return String(localized: .clipTypeImage)
        case .file: return String(localized: .clipTypeFile)
        }
    }
}

struct ClipItem: Identifiable, Equatable, Codable {
    var id: String
    var type: ClipItemType
    var contentHash: String
    var textContent: String?
    var rtfData: Data?
    var imageFilename: String?
    var thumbnailFilename: String?
    var fileURLs: [String]?
    var byteSize: Int
    var pixelWidth: Int?
    var pixelHeight: Int?
    var characterCount: Int?
    var sourceAppBundleID: String?
    var sourceAppName: String?
    var createdAt: Date
    var lastUsedAt: Date?
}

extension ClipItem {

    var previewLine: String {
        switch type {
        case .text, .link:
            let flattened = (textContent ?? "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "\n", with: " ")
            return String(flattened.prefix(200))
        case .image:
            if let width = pixelWidth, let height = pixelHeight {
                return String(localized: .imagePreviewFormat(width, height))
            }
            return String(localized: .clipTypeImage)
        case .file:
            let names = (fileURLs ?? []).map { URL(fileURLWithPath: $0).lastPathComponent }
            if names.count == 1 {
                return names[0]
            }
            return String(localized: .filesCountFormat(names.count))
        }
    }

    var formattedByteSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(byteSize), countStyle: .file)
    }
}

enum RetentionPeriod: String, Codable, CaseIterable, Equatable {
    case oneDay
    case sevenDays
    case oneMonth

    var displayName: String {
        switch self {
        case .oneDay: return String(localized: .retentionOneDay)
        case .sevenDays: return String(localized: .retentionSevenDays)
        case .oneMonth: return String(localized: .retentionOneMonth)
        }
    }

    var cutoffDate: Date {
        switch self {
        case .oneDay:
            return Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? .distantPast
        case .sevenDays:
            return Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        case .oneMonth:
            return Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? .distantPast
        }
    }
}

enum PanelMode: String, Codable, Equatable {
    case compact
    case full

    var toggled: PanelMode {
        self == .compact ? .full : .compact
    }
}
