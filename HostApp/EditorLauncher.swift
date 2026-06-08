// HostApp/EditorLauncher.swift
import AppKit

enum EditorLauncher {
    static let editorBundleID = "tr.gov.uyap.editor"
    static let editorFallbackPath = "/Applications/Uyap Doküman Editörü.app"

    static func editorURL() -> URL? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: editorBundleID) {
            return url
        }
        return FileManager.default.fileExists(atPath: editorFallbackPath)
            ? URL(fileURLWithPath: editorFallbackPath) : nil
    }

    static func open(url: URL) {
        guard let app = editorURL() else {
            let alert = NSAlert()
            alert.messageText = "UYAP Doküman Editörü bulunamadı"
            alert.informativeText = "Bu özelliği kullanmak için “Uyap Doküman Editörü” uygulamasını kurun."
            alert.runModal()
            return
        }
        let cfg = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([url], withApplicationAt: app, configuration: cfg) { _, error in
            guard let error = error else { return }
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Editörde açılamadı"
                alert.informativeText = error.localizedDescription
                alert.runModal()
            }
        }
    }
}
