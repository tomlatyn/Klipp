//
//  AccessibilityPermissionView.swift
//  Klipp
//
//  Created by Codex on 18.08.2026.
//

import SwiftUI

struct AccessibilityPermissionView: View {

    var onEnable: () -> Void
    var onNotNow: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.large) {
            Image(systemName: "accessibility")
                .font(AppTheme.Fonts.permissionIcon)
                .foregroundStyle(Color.accentColor)
                .frame(width: 64, height: 64)
                .background(Color.selectionTint, in: Circle())

            VStack(spacing: AppTheme.Spacing.small) {
                Text(String(localized: .accessibilityPermissionTitle))
                    .font(AppTheme.Fonts.permissionTitle)
                    .foregroundStyle(Color.primaryText)

                Text(String(localized: .accessibilityPermissionMessage))
                    .font(AppTheme.Fonts.rowCaption)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: AppTheme.Spacing.small) {
                Button(String(localized: .notNow), action: onNotNow)
                    .keyboardShortcut(.cancelAction)

                Button(String(localized: .enableAccessibility), action: onEnable)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(AppTheme.Spacing.section)
        .frame(width: 420, height: 280)
    }
}
