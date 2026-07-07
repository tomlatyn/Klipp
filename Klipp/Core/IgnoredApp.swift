//
//  IgnoredApp.swift
//  Klipp
//
//  Created by Tomáš Latýn on 07.07.2026.
//

import Foundation

struct IgnoredApp: Identifiable, Equatable, Codable {
    var bundleID: String
    var name: String

    var id: String { bundleID }
}
