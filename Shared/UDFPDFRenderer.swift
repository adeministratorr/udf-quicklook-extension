// Shared/UDFPDFRenderer.swift
import AppKit
import UDFKit

/// Render edilmiş attributed string'leri A4 sayfalı bir PDF'e (Data) çevirir.
/// NSLayoutManager ile sayfa başına bir NSTextContainer kullanır; header/footer
/// her sayfada margin bantlarında tekrar çizilir; .udfPageBreak'te yeni sayfa.
public enum UDFPDFRenderer {

    public static func pdfData(from url: URL) throws -> Data {
        let p = try UDFRenderer.parts(from: url)
        return pdfData(body: p.body, header: p.header, footer: p.footer, pageFormat: p.pageFormat)
    }

    public static func pdfData(body: NSAttributedString,
                               header: NSAttributedString,
                               footer: NSAttributedString,
                               pageFormat: PageFormat) -> Data {
        let portraitW: CGFloat = 595.28, portraitH: CGFloat = 841.89
        let landscape = pageFormat.paperOrientation == 2
        let pageW = landscape ? portraitH : portraitW
        let pageH = landscape ? portraitW : portraitH
        let mLeft = CGFloat(pageFormat.leftMargin)
        let mRight = CGFloat(pageFormat.rightMargin)
        let mTop = CGFloat(pageFormat.topMargin)
        let mBottom = CGFloat(pageFormat.bottomMargin)
        let usableW = max(pageW - mLeft - mRight, 1)
        let usableH = max(pageH - mTop - mBottom, 1)

        let outData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageW, height: pageH)
        guard let consumer = CGDataConsumer(data: outData as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        let headerLayout = header.length > 0 ? makeLayout(header, width: usableW) : nil
        let footerLayout = footer.length > 0 ? makeLayout(footer, width: usableW) : nil
        let footerH = footerLayout.map { $0.lm.usedRect(for: $0.container).height } ?? 0

        for segment in splitAtPageBreaks(body) {
            let lm = NSLayoutManager()
            let store = NSTextStorage(attributedString: segment)
            store.addLayoutManager(lm)

            var glyph = 0
            repeat {
                let container = NSTextContainer(size: CGSize(width: usableW, height: usableH))
                container.lineFragmentPadding = 0
                lm.addTextContainer(container)
                let range = lm.glyphRange(for: container)

                ctx.beginPDFPage(nil)
                ctx.saveGState()
                ctx.translateBy(x: 0, y: pageH)
                ctx.scaleBy(x: 1, y: -1)
                let ns = NSGraphicsContext(cgContext: ctx, flipped: true)
                NSGraphicsContext.saveGraphicsState()
                NSGraphicsContext.current = ns

                if let h = headerLayout {
                    let r = h.lm.glyphRange(for: h.container)
                    let p = CGPoint(x: mLeft, y: CGFloat(pageFormat.headerFOffset))
                    h.lm.drawBackground(forGlyphRange: r, at: p)
                    h.lm.drawGlyphs(forGlyphRange: r, at: p)
                }
                lm.drawBackground(forGlyphRange: range, at: CGPoint(x: mLeft, y: mTop))
                lm.drawGlyphs(forGlyphRange: range, at: CGPoint(x: mLeft, y: mTop))
                if let f = footerLayout {
                    let r = f.lm.glyphRange(for: f.container)
                    let p = CGPoint(x: mLeft, y: pageH - mBottom + CGFloat(pageFormat.footerFOffset) - footerH)
                    f.lm.drawBackground(forGlyphRange: r, at: p)
                    f.lm.drawGlyphs(forGlyphRange: r, at: p)
                }

                NSGraphicsContext.restoreGraphicsState()
                ctx.restoreGState()
                ctx.endPDFPage()

                let newGlyph = NSMaxRange(range)
                // İlerleme yoksa (boş segment ya da hiçbir glyph sığmayan dejenere margin)
                // bir sayfa basıp dur — sonsuz döngüyü önle.
                if newGlyph <= glyph { break }
                glyph = newGlyph
            } while glyph < lm.numberOfGlyphs
        }

        ctx.closePDF()
        return outData as Data
    }

    // MARK: - Helpers

    private struct Layout {
        let store: NSTextStorage   // lm.textStorage is `assign` (unretained) — keep storage alive
        let lm: NSLayoutManager
        let container: NSTextContainer
    }

    private static func makeLayout(_ s: NSAttributedString, width: CGFloat) -> Layout {
        let lm = NSLayoutManager()
        let store = NSTextStorage(attributedString: s)
        store.addLayoutManager(lm)
        let container = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        container.lineFragmentPadding = 0
        lm.addTextContainer(container)
        lm.ensureLayout(for: container)
        return Layout(store: store, lm: lm, container: container)
    }

    private static func splitAtPageBreaks(_ s: NSAttributedString) -> [NSAttributedString] {
        guard s.length > 0 else { return [s] }
        var segments: [NSAttributedString] = []
        var segStart = 0
        s.enumerateAttribute(.udfPageBreak, in: NSRange(location: 0, length: s.length), options: []) { value, range, _ in
            guard value != nil else { return }
            if range.location > segStart {
                segments.append(s.attributedSubstring(from: NSRange(location: segStart, length: range.location - segStart)))
            }
            segStart = range.location + range.length
        }
        if segStart < s.length {
            segments.append(s.attributedSubstring(from: NSRange(location: segStart, length: s.length - segStart)))
        }
        return segments.isEmpty ? [s] : segments
    }
}
