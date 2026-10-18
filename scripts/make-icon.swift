// scripts/make-icon.swift — UDFViewer ikonunu uretir (UYAP-editor ailesi stili:
// kirmizi squircle + beyaz daire + koyu harfler + kose noktasi). Kendi cizimimiz;
// resmi logonun kopyasi degildir. Cikti: assets/UDFViewer.iconset (iconutil icin).
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appendingPathComponent("assets/UDFViewer.iconset")
try? FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let redTop = NSColor(srgbRed: 0.90, green: 0.27, blue: 0.25, alpha: 1)
let redBottom = NSColor(srgbRed: 0.64, green: 0.07, blue: 0.09, alpha: 1)
let ink = NSColor(srgbRed: 0.29, green: 0.29, blue: 0.30, alpha: 1)

func render(px: Int) -> NSBitmapImageRep {
    let s = CGFloat(px)
    let u = s / 1024.0
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext

    // Squircle zemin
    let rect = NSRect(x: 26 * u, y: 26 * u, width: 972 * u, height: 972 * u)
    let squircle = NSBezierPath(roundedRect: rect, xRadius: 226 * u, yRadius: 226 * u)
    ctx.saveGState()
    squircle.addClip()
    NSGradient(starting: redTop, ending: redBottom)!.draw(in: rect, angle: -90)
    // Ust parlaklik bandi
    let gloss = NSRect(x: 26 * u, y: 620 * u, width: 972 * u, height: 378 * u)
    NSGradient(starting: NSColor(white: 1, alpha: 0.20), ending: NSColor(white: 1, alpha: 0.01))!
        .draw(in: gloss, angle: -90)
    ctx.restoreGState()

    // Beyaz daire
    let c = NSPoint(x: 512 * u, y: 524 * u)
    let r = 318 * u
    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: c.x - r, y: c.y - r, width: 2 * r, height: 2 * r)).fill()

    // "UDF" — yuvarlak hatli kalin font
    var desc = NSFont.systemFont(ofSize: 232 * u, weight: .bold).fontDescriptor
    if let rounded = desc.withDesign(.rounded) { desc = rounded }
    let font = NSFont(descriptor: desc, size: 232 * u) ?? NSFont.systemFont(ofSize: 232 * u, weight: .bold)
    let text = NSAttributedString(string: "UDF", attributes: [
        .font: font, .foregroundColor: ink, .kern: 6 * u,
    ])
    let ts = text.size()
    text.draw(at: NSPoint(x: c.x - ts.width / 2, y: c.y - ts.height / 2 + 8 * u))

    // Kose noktasi (aile imzasi)
    let dc = NSPoint(x: 806 * u, y: 228 * u)
    let dr = 104 * u
    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: dc.x - dr, y: dc.y - dr, width: 2 * dr, height: 2 * dr)).fill()
    ink.setFill()
    let dd = dr * 0.40
    NSBezierPath(ovalIn: NSRect(x: dc.x - dd, y: dc.y - dd, width: 2 * dd, height: 2 * dd)).fill()

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let entries: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, px) in entries {
    let rep = render(px: px)
    guard let data = rep.representation(using: .png, properties: [:]) else { continue }
    try? data.write(to: iconset.appendingPathComponent("\(name).png"))
}

let icns = root.appendingPathComponent("assets/UDFViewer.icns")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try task.run()
task.waitUntilExit()
if task.terminationStatus == 0 {
    print("OK: \(icns.path)")
} else {
    print("HATA: iconutil cikis kodu \(task.terminationStatus)")
    exit(1)
}
