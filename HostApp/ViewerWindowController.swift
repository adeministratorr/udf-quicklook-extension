// HostApp/ViewerWindowController.swift
import AppKit

final class ViewerWindowController: NSWindowController, NSToolbarDelegate {
    let sourceURL: URL
    private static let openInEditorItemID = NSToolbarItem.Identifier("OpenInEditor")

    init(url: URL, content: NSAttributedString) {
        self.sourceURL = url
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 1000),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = url.lastPathComponent
        window.center()

        let scroll = NSScrollView(frame: window.contentLayoutRect)
        scroll.hasVerticalScroller = true
        scroll.autoresizingMask = [.width, .height]

        let tv = NSTextView(frame: scroll.bounds)
        tv.isEditable = false
        tv.isSelectable = true
        tv.autoresizingMask = [.width]
        tv.textContainerInset = NSSize(width: 24, height: 24)
        tv.textStorage?.setAttributedString(content)
        tv.drawsBackground = true
        tv.backgroundColor = .white
        scroll.documentView = tv
        window.contentView = scroll
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
