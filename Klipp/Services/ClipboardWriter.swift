//
//  ClipboardWriter.swift
//  Klipp
//
//  Created by Tomáš Latýn on 06.07.2026.
//

import AppKit
import Foundation

final class ClipboardWriter {

    private let imageStore: ImageStore
    private let monitor: ClipboardMonitor

    init(imageStore: ImageStore, monitor: ClipboardMonitor) {
        self.imageStore = imageStore
        self.monitor = monitor
    }

    func write(_ item: ClipItem, plain: Bool = false) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.type {
        case .text, .link:
            if let text = item.textContent {
                pasteboard.setString(text, forType: .string)
            }
            if !plain, let rtfData = item.rtfData {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            if !plain, item.type == .link, let text = item.textContent, let url = URL(string: text) {
                (url as NSURL).write(to: pasteboard)
            }

        case .image:
            if let filename = item.imageFilename, let pngData = imageStore.imageData(named: filename) {
                pasteboard.setData(pngData, forType: .png)
                if let bitmap = NSBitmapImageRep(data: pngData),
                   let tiffData = bitmap.tiffRepresentation {
                    pasteboard.setData(tiffData, forType: .tiff)
                }
            }

        case .file:
            let urls = (item.fileURLs ?? []).map { URL(fileURLWithPath: $0) as NSURL }
            if !urls.isEmpty {
                pasteboard.writeObjects(urls)
            }
        }

        monitor.syncChangeCount()
    }
}
