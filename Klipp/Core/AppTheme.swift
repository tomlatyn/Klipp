//
//  AppTheme.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import SwiftUI

enum AppTheme {

    enum Spacing {
        /// 4 pt - Tight spacing between closely stacked elements (e.g. title and caption inside a row).
        static let tiny: CGFloat = 4

        /// 8 pt - Gap between icon and text inside rows and between metadata lines.
        static let small: CGFloat = 8

        /// 12 pt - Standard inner padding of list rows and gaps inside cards.
        static let medium: CGFloat = 12

        /// 16 pt - Horizontal padding of panel content and gap between list and detail pane.
        static let large: CGFloat = 16

        /// 28 pt - Spacing between top-level sections in settings and full history.
        static let section: CGFloat = 28
    }

    enum CornerRadius {
        /// 6 pt - Thumbnails and small previews.
        static let thumbnail: CGFloat = 6

        /// 10 pt - Selection highlight blocks and list rows.
        static let row: CGFloat = 10

        /// 22 pt - The floating panel surface.
        static let panel: CGFloat = 22
    }

    enum Fonts {
        /// 13 pt regular - Primary list row content.
        static let rowTitle = Font.system(size: 13)

        /// 12 pt regular - Secondary row content and detail text.
        static let rowCaption = Font.system(size: 12)

        /// 11 pt regular - Metadata labels, timestamps, and keyboard hints.
        static let metadata = Font.system(size: 11)

        /// 11 pt medium monospaced digits - Shortcut hints (e.g. ⌘1).
        static let shortcutHint = Font.system(size: 11, weight: .medium).monospacedDigit()
    }
}
