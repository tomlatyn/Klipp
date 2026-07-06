//
//  LaunchAtLoginService.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import Foundation
import ServiceManagement

enum LaunchAtLoginService {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}
