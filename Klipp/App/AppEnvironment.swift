//
//  AppEnvironment.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import AppKit
import Foundation

final class AppEnvironment {

    static let shared = AppEnvironment()

    let imageStore: ImageStore
    let clipStore: ClipStore
    let monitor: ClipboardMonitor
    let clipboardWriter: ClipboardWriter
    let pasteService: PasteService
    let hotKey: HotKeyService

    weak var store: KlippStore?

    private let workQueue = DispatchQueue(label: "com.latyn.Klipp.storage", qos: .utility)
    private var retentionTimer: Timer?

    private init() {
        let supportDirectory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Klipp", isDirectory: true)

        let imageStore = ImageStore(directoryURL: supportDirectory.appendingPathComponent("images", isDirectory: true))
        self.imageStore = imageStore

        do {
            clipStore = try ClipStore(
                databaseURL: supportDirectory.appendingPathComponent("klipp.sqlite"),
                imageStore: imageStore
            )
        } catch {
            fatalError("Failed to open the Klipp database: \(error)")
        }

        monitor = ClipboardMonitor()
        clipboardWriter = ClipboardWriter(imageStore: imageStore, monitor: monitor)
        pasteService = PasteService()
        hotKey = HotKeyService()
    }

    func bootstrap(store: KlippStore) {
        self.store = store
        PanelController.shared.store = store

        monitor.onCapture = { [weak store] capture in
            store?.send(.clipboardCaptured(capture))
        }

        hotKey.onHotKey = { [weak store] in
            store?.send(.hotKeyPressed)
        }
    }

    func startCoreServices() {
        clipStore.startObserving { [weak self] items in
            self?.store?.send(.itemsChanged(items))
        }

        monitor.isPaused = AppDefaults.isMonitoringPaused
        monitor.ignoredBundleIDs = Set(AppDefaults.ignoredApps.map(\.bundleID))
        monitor.start()
        pasteService.start()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak pasteService] in
            pasteService?.requestAccessibilityAccessIfNeeded()
        }

        hotKey.register(AppDefaults.hotKeyShortcut)

        LaunchAtLoginService.reconcile(shouldEnable: AppDefaults.launchAtLogin)

        cleanupExpired(retention: AppDefaults.retentionPeriod)
        workQueue.async { [clipStore] in
            clipStore.cleanupOrphanedImages()
        }

        let timer = Timer(timeInterval: 3600, repeats: true) { [weak self] _ in
            self?.store?.send(.retentionTick)
        }
        RunLoop.main.add(timer, forMode: .common)
        retentionTimer = timer
    }

    func insertCapture(_ capture: ClipboardCapture) {
        workQueue.async { [clipStore] in
            clipStore.insert(capture)
        }
    }

    func cleanupExpired(retention: RetentionPeriod) {
        workQueue.async { [clipStore] in
            clipStore.cleanupExpired(retention: retention)
        }
    }

    func deleteItem(id: String) {
        workQueue.async { [clipStore] in
            clipStore.delete(id: id)
        }
    }

    func togglePin(id: String) {
        workQueue.async { [clipStore] in
            clipStore.togglePin(id: id)
        }
    }

    func clearHistory() {
        workQueue.async { [clipStore] in
            clipStore.clearAll()
        }
    }

    func computeStorageSize(completion: @escaping (Int) -> Void) {
        let supportDirectory = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Klipp", isDirectory: true)

        workQueue.async {
            var total = 0
            let enumerator = FileManager.default.enumerator(
                at: supportDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            while let url = enumerator?.nextObject() as? URL {
                total += (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            }
            completion(total)
        }
    }
}
