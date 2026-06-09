// HostApp/ViewerWindowController.swift
import AppKit
import PDFKit
import UDFRender

final class ViewerWindowController: NSWindowController, NSToolbarDelegate {
    let sourceURL: URL
    private static let openInEditorItemID = NSToolbarItem.Identifier("OpenInEditor")

    init(url: URL) {
        self.sourceURL = url
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 1000),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = url.lastPathComponent
        window.center()

        let pdfView = PDFView(frame: window.contentLayoutRect)
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.pageShadowsEnabled = true
        pdfView.backgroundColor = NSColor(white: 0.85, alpha: 1.0)
        pdfView.autoresizingMask = [.width, .height]
        if let data = try? UDFPDFRenderer.pdfData(from: url) {
            pdfView.document = PDFDocument(data: data)
        }
        window.contentView = pdfView
        window.appearance = NSAppearance(named: .aqua)

        super.init(window: window)

        let toolbar = NSToolbar(identifier: "ViewerToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconAndLabel
        window.toolbar = toolbar
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc func openInEditor(_ sender: Any?) {
        EditorLauncher.open(url: sourceURL)
    }

    // MARK: NSToolbarDelegate
    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard id == Self.openInEditorItemID else { return nil }
        let item = NSToolbarItem(itemIdentifier: id)
        item.label = "UYAP Editöründe Aç"
        item.paletteLabel = item.label
        item.image = NSImage(systemSymbolName: "square.and.pencil",
                             accessibilityDescription: item.label)
        item.target = self
        item.action = #selector(openInEditor(_:))
        return item
    }
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.openInEditorItemID]
    }
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [Self.openInEditorItemID]
    }
}
