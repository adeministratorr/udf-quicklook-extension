// QuickLookPreview/PreviewViewController.swift
import AppKit
import Quartz   // QLPreviewingController
import UDFRender

@objc(PreviewViewController)
final class PreviewViewController: NSViewController, QLPreviewingController {
    private var textView: NSTextView!

    override func loadView() {
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 600, height: 800))
        scroll.hasVerticalScroller = true
        scroll.autoresizingMask = [.width, .height]

        let tv = NSTextView(frame: scroll.bounds)
        tv.isEditable = false
        tv.isSelectable = true
        tv.autoresizingMask = [.width]
        tv.textContainerInset = NSSize(width: 16, height: 16)
        scroll.documentView = tv

        tv.drawsBackground = true
        tv.backgroundColor = .white
        scroll.appearance = NSAppearance(named: .aqua)

        self.textView = tv
        self.view = scroll
    }

    func preparePreviewOfFile(at url: URL,
                              completionHandler handler: @escaping (Error?) -> Void) {
        do {
            let attr = try UDFRenderer.attributedString(from: url)
            textView.textStorage?.setAttributedString(attr)
            handler(nil)
        } catch {
            handler(error)
        }
    }
}
