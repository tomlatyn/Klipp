//
//  AboutView.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import SwiftUI

struct AboutView: View {

    private var version: String {
        let short = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)

            VStack(spacing: AppTheme.Spacing.tiny) {
                Text(String(localized: .appName))
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.primaryText)

                Text(String(localized: .aboutVersionFormat(version)))
                    .font(AppTheme.Fonts.rowCaption)
                    .foregroundStyle(Color.secondaryText)
            }

            Text(String(localized: .aboutTagline))
                .font(AppTheme.Fonts.rowCaption)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            Text(String(localized: .copyright))
                .font(AppTheme.Fonts.metadata)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(AppTheme.Spacing.section)
        .frame(width: 300)
    }
}
