//
//  ImageStore.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import AppKit
import Foundation

final class ImageStore {

    struct SavedImage {
        let imageFilename: String
        let thumbnailFilename: String
    }

    private let directoryURL: URL
    private let thumbnailCache = NSCache<NSString, NSImage>()
    private static let thumbnailMaxDimension: CGFloat = 320

    init(directoryURL: URL) {
        self.directoryURL = directoryURL
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        thumbnailCache.countLimit = 200
    }

    func save(pngData: Data, id: String) throws -> SavedImage {
        let imageFilename = "\(id).png"
        let thumbnailFilename = "\(id)_thumb.png"

        try pngData.write(to: directoryURL.appendingPathComponent(imageFilename))

        if let thumbnailData = Self.thumbnailPNG(from: pngData) {
            try thumbnailData.write(to: directoryURL.appendingPathComponent(thumbnailFilename))
        }

        return SavedImage(imageFilename: imageFilename, thumbnailFilename: thumbnailFilename)
    }

    func imageData(named filename: String) -> Data? {
        try? Data(contentsOf: directoryURL.appendingPathComponent(filename))
    }

    func image(named filename: String) -> NSImage? {
        NSImage(contentsOf: directoryURL.appendingPathComponent(filename))
    }

    func thumbnail(named filename: String) -> NSImage? {
        if let cached = thumbnailCache.object(forKey: filename as NSString) {
            return cached
        }

        guard let image = NSImage(contentsOf: directoryURL.appendingPathComponent(filename)) else {
            return nil
        }

        thumbnailCache.setObject(image, forKey: filename as NSString)
        return image
    }

    func deleteFiles(_ filenames: [String]) {
        for filename in filenames {
            try? FileManager.default.removeItem(at: directoryURL.appendingPathComponent(filename))
            thumbnailCache.removeObject(forKey: filename as NSString)
        }
    }

    func removeAll() {
        thumbnailCache.removeAllObjects()
        let contents = (try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)) ?? []
        for url in contents {
            try? FileManager.default.removeItem(at: url)
        }
    }

    func cleanupOrphans(validFilenames: Set<String>) {
        let contents = (try? FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)) ?? []
        for url in contents where !validFilenames.contains(url.lastPathComponent) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func thumbnailPNG(from pngData: Data) -> Data? {
        guard let image = NSImage(data: pngData) else { return nil }

        let size = image.size
        guard size.width > 0, size.height > 0 else { return nil }

        let scale = min(1, thumbnailMaxDimension / max(size.width, size.height))
        let targetSize = NSSize(width: size.width * scale, height: size.height * scale)

        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(targetSize.width),
            pixelsHigh: Int(targetSize.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        bitmap.size = targetSize

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: .zero,
            operation: .copy,
            fraction: 1
        )
        NSGraphicsContext.restoreGraphicsState()

        return bitmap.representation(using: .png, properties: [:])
    }
}
