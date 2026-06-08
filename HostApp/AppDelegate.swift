// HostApp/AppDelegate.swift
import AppKit
import UniformTypeIdentifiers
import UDFRender

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var controllers: [ViewerWindowController] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMainMenu()
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { openDocument(url) }
    }

    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { false }

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
        do {
            let attr = try UDFRenderer.attributedString(from: url)
            let controller = ViewerWindowController(url: url, content: attr)
            controller.showWindow(nil)
            controller.window?.makeKeyAndOrderFront(nil)
            controllers.append(controller)
            controller.window?.delegate = self
        } catch {
            let alert = NSAlert()
            alert.messageText = "Belge açılamadı"
            alert.informativeText = "\(url.lastPathComponent): \(error.localizedDescription)"
            alert.runModal()
        }
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }
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
