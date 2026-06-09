// QuickLookThumbnail/ThumbnailProvider.swift
import AppKit
import PDFKit
import QuickLookThumbnailing
import UDFRender

@objc(ThumbnailProvider)
final class ThumbnailProvider: QLThumbnailProvider {
    override func provideThumbnail(
        for request: QLFileThumbnailRequest,
        _ handler: @escaping (QLThumbnailReply?, Error?) -> Void
    ) {
        let pdfData: Data
        do {
            pdfData = try UDFPDFRenderer.pdfData(from: request.fileURL)
        } catch {
            handler(nil, error)
            return
        }
        guard let doc = PDFDocument(data: pdfData), let page = doc.page(at: 0) else {
            handler(nil, NSError(domain: "UDFThumbnail", code: 1,
                                 userInfo: [NSLocalizedDescriptionKey: "PDF sayfası yok"]))
            return
        }

        let maxSize = request.maximumSize
        let pageRect = page.bounds(for: .mediaBox)
        // A4 oranını koruyarak istenen kutuya sığdır.
        let scale = min(maxSize.width / pageRect.width, maxSize.height / pageRect.height)
        let size = NSSize(width: pageRect.width * scale, height: pageRect.height * scale)

        let reply = QLThumbnailReply(contextSize: size) { () -> Bool in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            NSColor.white.setFill()
            NSRect(origin: .zero, size: size).fill()
            ctx.saveGState()
            ctx.scaleBy(x: scale, y: scale)
            page.draw(with: .mediaBox, to: ctx)   // PDF sayfası y-up context'e dik çizilir
            ctx.restoreGState()
            return true
        }
        handler(reply, nil)
    }
}
