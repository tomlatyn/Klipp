//
//  ClipStore.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import Foundation
import GRDB

extension ClipItem: FetchableRecord, PersistableRecord {

    static let databaseTableName = "clip_item"

    enum Columns {
        static let contentHash = Column("contentHash")
        static let createdAt = Column("createdAt")
        static let type = Column("type")
        static let isPinned = Column("isPinned")
    }
}

final class ClipStore {

    static let maxItemCount = 1000

    private let dbQueue: DatabaseQueue
    private let imageStore: ImageStore
    private var observationCancellable: AnyDatabaseCancellable?

    init(databaseURL: URL, imageStore: ImageStore) throws {
        self.imageStore = imageStore

        try FileManager.default.createDirectory(
            at: databaseURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        dbQueue = try DatabaseQueue(path: databaseURL.path)

        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            try db.create(table: ClipItem.databaseTableName) { t in
                t.primaryKey("id", .text)
                t.column("type", .text).notNull()
                t.column("contentHash", .text).notNull().unique()
                t.column("textContent", .text)
                t.column("rtfData", .blob)
                t.column("imageFilename", .text)
                t.column("thumbnailFilename", .text)
                t.column("fileURLs", .text)
                t.column("byteSize", .integer).notNull().defaults(to: 0)
                t.column("pixelWidth", .integer)
                t.column("pixelHeight", .integer)
                t.column("characterCount", .integer)
                t.column("sourceAppBundleID", .text)
                t.column("sourceAppName", .text)
                t.column("createdAt", .datetime).notNull().indexed()
                t.column("lastUsedAt", .datetime)
                t.column("isPinned", .boolean).notNull().defaults(to: false)
            }
        }
        try migrator.migrate(dbQueue)
    }

    func startObserving(onChange: @escaping ([ClipItem]) -> Void) {
        let observation = ValueObservation.tracking { db in
            try ClipItem
                .order(ClipItem.Columns.isPinned.desc, ClipItem.Columns.createdAt.desc)
                .fetchAll(db)
        }

        observationCancellable = observation.start(
            in: dbQueue,
            scheduling: .async(onQueue: .main),
            onError: { _ in },
            onChange: onChange
        )
    }

    func insert(_ capture: ClipboardCapture) {
        let now = Date()

        let bumped: Bool = (try? dbQueue.write { db in
            if var existing = try ClipItem
                .filter(ClipItem.Columns.contentHash == capture.contentHash)
                .fetchOne(db) {
                existing.createdAt = now
                existing.lastUsedAt = now
                try existing.update(db)
                return true
            }
            return false
        }) ?? false

        if bumped {
            return
        }

        var item = ClipItem(
            id: UUID().uuidString,
            type: capture.type,
            contentHash: capture.contentHash,
            textContent: capture.textContent,
            rtfData: capture.rtfData,
            imageFilename: nil,
            thumbnailFilename: nil,
            fileURLs: capture.fileURLs,
            byteSize: capture.byteSize,
            pixelWidth: capture.pixelWidth,
            pixelHeight: capture.pixelHeight,
            characterCount: capture.characterCount,
            sourceAppBundleID: capture.sourceAppBundleID,
            sourceAppName: capture.sourceAppName,
            createdAt: now,
            lastUsedAt: nil,
            isPinned: false
        )

        if let pngData = capture.imagePNGData {
            guard let saved = try? imageStore.save(pngData: pngData, id: item.id) else { return }
            item.imageFilename = saved.imageFilename
            item.thumbnailFilename = saved.thumbnailFilename
        }

        let orphanedFilenames: [String] = (try? dbQueue.write { db in
            try item.insert(db)
            return try Self.enforceItemCap(db)
        }) ?? []

        imageStore.deleteFiles(orphanedFilenames)
    }

    func touch(id: String) {
        let now = Date()
        try? dbQueue.write { db in
            if var item = try ClipItem.fetchOne(db, key: id) {
                item.createdAt = now
                item.lastUsedAt = now
                try item.update(db)
            }
        }
    }

    func togglePin(id: String) {
        try? dbQueue.write { db in
            if var item = try ClipItem.fetchOne(db, key: id) {
                item.isPinned.toggle()
                try item.update(db)
            }
        }
    }

    func fetchItem(id: String) -> ClipItem? {
        try? dbQueue.read { db in
            try ClipItem.fetchOne(db, key: id)
        }
    }

    func delete(id: String) {
        let filenames: [String] = (try? dbQueue.write { db in
            guard let item = try ClipItem.fetchOne(db, key: id) else { return [] }
            try item.delete(db)
            return Self.imageFilenames(of: [item])
        }) ?? []

        imageStore.deleteFiles(filenames)
    }

    func clearAll() {
        let filenames: [String] = (try? dbQueue.write { db in
            let removed = try ClipItem
                .filter(ClipItem.Columns.isPinned == false)
                .fetchAll(db)
            try ClipItem
                .filter(ClipItem.Columns.isPinned == false)
                .deleteAll(db)
            return Self.imageFilenames(of: removed)
        }) ?? []

        imageStore.deleteFiles(filenames)
    }

    func cleanupExpired(retention: RetentionPeriod) {
        let cutoff = retention.cutoffDate

        let filenames: [String] = (try? dbQueue.write { db in
            let expired = try ClipItem
                .filter(ClipItem.Columns.createdAt < cutoff && ClipItem.Columns.isPinned == false)
                .fetchAll(db)
            try ClipItem
                .filter(ClipItem.Columns.createdAt < cutoff && ClipItem.Columns.isPinned == false)
                .deleteAll(db)
            return Self.imageFilenames(of: expired)
        }) ?? []

        imageStore.deleteFiles(filenames)
    }

    func cleanupOrphanedImages() {
        let validFilenames: Set<String> = (try? dbQueue.read { db in
            let items = try ClipItem.filter(ClipItem.Columns.type == ClipItemType.image.rawValue).fetchAll(db)
            return Set(Self.imageFilenames(of: items))
        }) ?? []

        imageStore.cleanupOrphans(validFilenames: validFilenames)
    }

    private static func enforceItemCap(_ db: Database) throws -> [String] {
        let unpinnedCount = try ClipItem
            .filter(ClipItem.Columns.isPinned == false)
            .fetchCount(db)
        guard unpinnedCount > maxItemCount else { return [] }

        let overflow = try ClipItem
            .filter(ClipItem.Columns.isPinned == false)
            .order(ClipItem.Columns.createdAt.asc)
            .limit(unpinnedCount - maxItemCount)
            .fetchAll(db)

        for item in overflow {
            try item.delete(db)
        }

        return imageFilenames(of: overflow)
    }

    private static func imageFilenames(of items: [ClipItem]) -> [String] {
        items.flatMap { [$0.imageFilename, $0.thumbnailFilename].compactMap { $0 } }
    }
}
