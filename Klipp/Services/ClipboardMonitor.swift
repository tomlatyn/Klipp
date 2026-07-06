//
//  ClipboardMonitor.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import AppKit
import CryptoKit
import Foundation

struct ClipboardCapture {
    var type: ClipItemType
    var contentHash: String
    var textContent: String?
    var rtfData: Data?
    var imagePNGData: Data?
    var fileURLs: [String]?
    var byteSize: Int
    var pixelWidth: Int?
    var pixelHeight: Int?
    var characterCount: Int?
    var sourceAppBundleID: String?
    var sourceAppName: String?
}

final class ClipboardMonitor {

    static let maxImageByteSize = 20 * 1024 * 1024

    var onCapture: ((ClipboardCapture) -> Void)?
    var isPaused = false

    private var timer: Timer?
    private var lastChangeCount = NSPasteboard.general.changeCount

    private static let concealedType = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    private static let transientType = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")

    func start() {
        guard timer == nil else { return }

        let timer = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func syncChangeCount() {
        lastChangeCount = NSPasteboard.general.changeCount
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general

        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard !isPaused else { return }
        guard let types = pasteboard.types, !types.isEmpty else { return }

        if types.contains(Self.concealedType) || types.contains(Self.transientType) {
            return
        }

        guard var capture = Self.readCapture(from: pasteboard) else { return }

        let frontmost = NSWorkspace.shared.frontmostApplication
        capture.sourceAppBundleID = frontmost?.bundleIdentifier
        capture.sourceAppName = frontmost?.localizedName

        onCapture?(capture)
    }

    private static func readCapture(from pasteboard: NSPasteboard) -> ClipboardCapture? {
        if let fileCapture = readFiles(from: pasteboard) {
            return fileCapture
        }
        if let imageCapture = readImage(from: pasteboard) {
            return imageCapture
        }
        return readText(from: pasteboard)
    }

    private static func readFiles(from pasteboard: NSPasteboard) -> ClipboardCapture? {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]

        guard
            let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
            !urls.isEmpty
        else { return nil }

        let paths = urls.map(\.path)
        let joined = paths.joined(separator: "\n")

        var totalSize = 0
        for path in paths {
            let attributes = try? FileManager.default.attributesOfItem(atPath: path)
            totalSize += (attributes?[.size] as? Int) ?? 0
        }

        return ClipboardCapture(
            type: .file,
            contentHash: hash(of: Data(joined.utf8)),
            textContent: joined,
            rtfData: nil,
            imagePNGData: nil,
            fileURLs: paths,
            byteSize: totalSize,
            pixelWidth: nil,
            pixelHeight: nil,
            characterCount: nil,
            sourceAppBundleID: nil,
            sourceAppName: nil
        )
    }

    private static func readImage(from pasteboard: NSPasteboard) -> ClipboardCapture? {
        guard let rawData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) else {
            return nil
        }

        guard let bitmap = NSBitmapImageRep(data: rawData) else { return nil }
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else { return nil }
        guard pngData.count <= maxImageByteSize else { return nil }

        return ClipboardCapture(
            type: .image,
            contentHash: hash(of: pngData),
            textContent: nil,
            rtfData: nil,
            imagePNGData: pngData,
            fileURLs: nil,
            byteSize: pngData.count,
            pixelWidth: bitmap.pixelsWide,
            pixelHeight: bitmap.pixelsHigh,
            characterCount: nil,
            sourceAppBundleID: nil,
            sourceAppName: nil
        )
    }

    private static func readText(from pasteboard: NSPasteboard) -> ClipboardCapture? {
        guard let string = pasteboard.string(forType: .string) else { return nil }

        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let type: ClipItemType = isWebLink(trimmed) ? .link : .text
        let rtfData = pasteboard.data(forType: .rtf)

        return ClipboardCapture(
            type: type,
            contentHash: hash(of: Data(string.utf8)),
            textContent: string,
            rtfData: rtfData,
            imagePNGData: nil,
            fileURLs: nil,
            byteSize: string.utf8.count,
            pixelWidth: nil,
            pixelHeight: nil,
            characterCount: string.count,
            sourceAppBundleID: nil,
            sourceAppName: nil
        )
    }

    private static func isWebLink(_ string: String) -> Bool {
        guard !string.contains(where: \.isWhitespace) else { return false }
        guard let url = URL(string: string), let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    private static func hash(of data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
