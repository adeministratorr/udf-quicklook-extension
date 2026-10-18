// HostApp/AppDelegate.swift
import AppKit
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var controllers: [ViewerWindowController] = []
    private var welcomeWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
        // Belgeler acikken degil; bos baslatmada kisa bir gecikmeyle karsilama
        // penceresini goster (Finder'dan gelen "open" olaylarina firsat ver).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self, self.controllers.isEmpty, self.welcomeWindow == nil else { return }
            self.showWelcome()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { openDocument(url) }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag, controllers.isEmpty { showWelcome() }
        return true
    }

    @objc func openMenuAction(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        if let udf = UTType("com.uyap.udf") { panel.allowedContentTypes = [udf] }
        if panel.runModal() == .OK { for url in panel.urls { openDocument(url) } }
    }

    @objc func openInEditorMenu(_ sender: Any?) {
        (NSApp.keyWindow?.windowController as? ViewerWindowController)?.openInEditor(sender)
    }

    private func openDocument(_ url: URL) {
        welcomeWindow?.close()
        welcomeWindow = nil
        let controller = ViewerWindowController(url: url)
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        controllers.append(controller)
        controller.window?.delegate = self
    }

    private func showWelcome() {
        if let w = welcomeWindow { w.makeKeyAndOrderFront(nil); return }
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 320),
            styleMask: [.titled, .closable], backing: .buffered, defer: false)
        window.title = "UDF Görüntüleyici"
        window.center()

        let drop = DropView(frame: window.contentLayoutRect)
        drop.onDrop = { [weak self] urls in urls.forEach { self?.openDocument($0) } }
        drop.autoresizingMask = [.width, .height]

        let icon = NSImageView()
        icon.image = NSApp.applicationIconImage
        icon.imageScaling = .scaleProportionallyUpOrDown
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.widthAnchor.constraint(equalToConstant: 96).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 96).isActive = true

        let title = NSTextField(labelWithString: "UDF dosyanızı buraya sürükleyin")
        title.font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        let hint = NSTextField(labelWithString: "veya aşağıdaki düğmeyle seçin (⌘O)")
        hint.textColor = .secondaryLabelColor

        let button = NSButton(title: "Dosya Aç…", target: self, action: #selector(openMenuAction(_:)))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"

        let stack = NSStackView(views: [icon, title, hint, button])
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        drop.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: drop.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: drop.centerYAnchor),
        ])
        window.contentView = drop
        window.delegate = self
        welcomeWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
        if window === welcomeWindow { welcomeWindow = nil }
        controllers.removeAll { $0.window === window }
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem(); mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "UDF Görüntüleyici Hakkında", action: nil, keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Çıkış", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu

        let fileItem = NSMenuItem(); mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "Dosya")
        let open = NSMenuItem(title: "Aç…", action: #selector(openMenuAction(_:)), keyEquivalent: "o")
        open.target = self; fileMenu.addItem(open)
        let inEditor = NSMenuItem(title: "UYAP Editöründe Aç", action: #selector(openInEditorMenu(_:)), keyEquivalent: "e")
        inEditor.target = self; fileMenu.addItem(inEditor)
        fileMenu.addItem(.separator())
        fileMenu.addItem(NSMenuItem(title: "Kapat", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        fileItem.submenu = fileMenu

        let editItem = NSMenuItem(); mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Düzen")
        editMenu.addItem(withTitle: "Kopyala", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Tümünü Seç", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        NSApplication.shared.mainMenu = mainMenu
    }
}

/// Finder'dan sürüklenen .udf dosyalarını kabul eden basit görünüm.
final class DropView: NSView {
    var onDrop: (([URL]) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
        wantsLayer = true
        layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation { .copy }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL],
              !urls.isEmpty
        else { return false }
        onDrop?(urls)
        return true
    }
}
