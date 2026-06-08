// QuickLookThumbnail/ThumbnailProvider.swift
import AppKit
import QuickLookThumbnailing
import UDFRender

@objc(ThumbnailProvider)
final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let attr: NSAttributedString
        do {
            attr = try UDFRenderer.attributedString(from: request.fileURL)
        } catch {
            handler(nil, error)
            return
        }

        let size = request.maximumSize
        let inset = size.width * 0.06
        let textRect = NSRect(x: inset, y: inset,
                              width: size.width - 2 * inset,
                              height: size.height - 2 * inset)

        // The QuickLook thumbnail context is a standard non-flipped (y-up,
        // bottom-left origin) context. `draw(with:.usesLineFragmentOrigin)` renders
        // the text upright, top-down, within the rect — no manual flip needed.
        // (An earlier manual CGContext flip rendered the thumbnail upside-down.)
        let reply = QLThumbnailReply(contextSize: size) { () -> Bool in
            NSColor.white.setFill()
            NSRect(origin: .zero, size: size).fill()
            attr.draw(with: textRect,
                      options: [.usesLineFragmentOrigin, .truncatesLastVisibleLine])
            return true
        }
        handler(reply, nil)
    }
}
