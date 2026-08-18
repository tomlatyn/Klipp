//
//  LaunchAtLoginService.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import Foundation
import OSLog
import ServiceManagement

enum LaunchAtLoginService {

    enum UpdateResult {
        case completed
        case requiresApproval
    }

    private static let logger = Logger(subsystem: "com.latyn.Klipp", category: "LaunchAtLogin")

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws -> UpdateResult {
        let service = SMAppService.mainApp

        if enabled {
            switch service.status {
            case .enabled:
                return .completed
            case .requiresApproval:
                SMAppService.openSystemSettingsLoginItems()
                return .requiresApproval
            case .notRegistered, .notFound:
                try service.register()
                if service.status == .requiresApproval {
                    SMAppService.openSystemSettingsLoginItems()
                    return .requiresApproval
                }
                return .completed
            @unknown default:
                try service.register()
                return .completed
            }
        } else {
            switch service.status {
            case .enabled, .requiresApproval:
                try service.unregister()
                return .completed
            case .notRegistered, .notFound:
                return .completed
            @unknown default:
                try service.unregister()
                return .completed
            }
        }
    }

    static func reconcile(shouldEnable: Bool) {
        let service = SMAppService.mainApp

        do {
            if shouldEnable, (service.status == .notRegistered || service.status == .notFound) {
                try service.register()
            } else if !shouldEnable, (service.status == .enabled || service.status == .requiresApproval) {
                try service.unregister()
            }
        } catch {
            logger.error("Failed to reconcile login item: \(error.localizedDescription, privacy: .public)")
        }
    }
}
