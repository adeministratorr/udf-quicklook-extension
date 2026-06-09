// QuickLookPreview/PreviewViewController.swift
import AppKit
import Quartz       // QLPreviewingController
import PDFKit
import UDFRender

@objc(PreviewViewController)
final class PreviewViewController: NSViewController, QLPreviewingController {
    private var pdfView: PDFView!
    private var thumbnailView: PDFThumbnailView!

    override func loadView() {
        let pdf = PDFView(frame: NSRect(x: 0, y: 0, width: 800, height: 1000))
        pdf.autoScales = true
        pdf.displayMode = .singlePageContinuous
        pdf.displayDirection = .vertical
        pdf.pageShadowsEnabled = true
        pdf.backgroundColor = NSColor(white: 0.85, alpha: 1.0)
        pdf.autoresizingMask = [.width, .height]

        let thumbs = PDFThumbnailView()
        thumbs.pdfView = pdf
        thumbs.thumbnailSize = NSSize(width: 100, height: 140)
        thumbs.backgroundColor = NSColor(white: 0.92, alpha: 1.0)

        let split = NSSplitView(frame: pdf.bounds)
        split.isVertical = true
        split.dividerStyle = .thin
        split.autoresizingMask = [.width, .height]
        split.addArrangedSubview(thumbs)
        split.addArrangedSubview(pdf)
        thumbs.setFrameSize(NSSize(width: 120, height: split.bounds.height))

        self.pdfView = pdf
        self.thumbnailView = thumbs
        self.view = split
    }

    func preparePreviewOfFile(at url: URL,
                              completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let data = try UDFPDFRenderer.pdfData(from: url)
            guard let doc = PDFDocument(data: data) else {
                handler(NSError(domain: "UDFPreview", code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "PDF oluşturulamadı"]))
                return
            }
            pdfView.document = doc
            thumbnailView.isHidden = (doc.pageCount <= 1)
            handler(nil)
        } catch {
            handler(error)
        }
    }
}
