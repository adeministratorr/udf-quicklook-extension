import AppKit
import ImageIO
import UDFKit

/// Decodes image bytes in-process via ImageIO (CGImageSource), which works inside
/// the App Sandbox used by the QuickLook extensions.
private func udfDecodeImage(_ data: Data) -> NSImage? {
    guard let src = CGImageSourceCreateWithData(data as CFData, nil),
          let cg = CGImageSourceCreateImageAtIndex(src, 0, nil) else { return nil }
    return NSImage(cgImage: cg, size: .zero)
}

/// Tracks running item counts per listId so numbered markers are computed
/// correctly across the whole document.
final class ListCounterState {
    private var perListId: [Int: Int] = [:]
    private var anonymous: Int = 0

    func nextItemNumber(for list: ListProperties) -> Int {
        if let id = list.listId {
            perListId[id, default: 0] += 1
            return perListId[id]!
        }
        anonymous += 1
        return anonymous
    }
}

struct DocumentToAttributedString {

    static func convert(_ doc: UDFDocument) -> NSAttributedString {
        return convertBlocks(doc.body)
    }

    /// Convert an arbitrary list of block elements (body, header, or footer)
    /// into an editable `NSAttributedString`.
    static func convertBlocks(_ blocks: [BlockElement]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let counters = ListCounterState()
        appendBlocks(blocks, to: result, cellBlock: nil, counters: counters)

        // Remove trailing newline if present
        if result.length > 0 && result.string.hasSuffix("\n") {
            result.deleteCharacters(in: NSRange(location: result.length - 1, length: 1))
        }

        return result
    }

    /// Render exactly one table, preserving the trailing paragraph break so it
    /// can replace a table's character range without merging into the next block.
    static func convertTable(_ table: Table) -> NSAttributedString {
        let result = NSMutableAttributedString()
        appendBlocks([.table(table)], to: result, cellBlock: nil, counters: ListCounterState())
        return result
    }

    /// Append block elements to result. If cellBlock is non-nil, all paragraphs get that textBlock.
    private static func appendBlocks(
        _ blocks: [BlockElement],
        to result: NSMutableAttributedString,
        cellBlock: NSTextTableBlock?,
        counters: ListCounterState
    ) {
        for block in blocks {
            switch block {
            case .paragraph(let para):
                appendParagraph(para, to: result, cellBlock: cellBlock, counters: counters)
            case .table(let table):
                // Ensure there's a newline before the table starts
                // NSTextTable needs a clean paragraph break before the first cell
                if result.length > 0 && !result.string.hasSuffix("\n") {
                    result.append(NSAttributedString(string: "\n", attributes: defaultAttributes()))
                }
                appendTable(table, to: result)
            case .pageBreak:
                if result.length > 0 && !result.string.hasSuffix("\n") {
                    result.append(NSAttributedString(string: "\n", attributes: defaultAttributes()))
                }
                // Görünmez sayfa-sonu işaretçisi: PDF üreteci .udfPageBreak taşıyan
                // aralıkta gövdeyi bölüp sonraki segmenti yeni sayfada başlatır.
                var attrs = defaultAttributes()
                attrs[.udfPageBreak] = true
                result.append(NSAttributedString(string: "\n", attributes: attrs))
            }
        }
    }

    // MARK: - Paragraph

    /// Append a single paragraph. Each paragraph ends with \n.
    /// If cellBlock is set, the paragraph style includes that textBlock.
    private static func appendParagraph(
        _ para: Paragraph,
        to result: NSMutableAttributedString,
        cellBlock: NSTextTableBlock?,
        counters: ListCounterState
    ) {
        let paragraphStyle = NSMutableParagraphStyle()

        switch para.alignment {
        case .left: paragraphStyle.alignment = .left
        case .center: paragraphStyle.alignment = .center
        case .right: paragraphStyle.alignment = .right
        case .justify: paragraphStyle.alignment = .justified
        }

        paragraphStyle.headIndent = CGFloat(para.leftIndent)
        paragraphStyle.tailIndent = para.rightIndent > 0 ? CGFloat(-para.rightIndent) : 0
        paragraphStyle.firstLineHeadIndent = CGFloat(para.leftIndent + para.firstLineIndent)

        if para.lineSpacing > 0 {
            paragraphStyle.lineHeightMultiple = CGFloat(1.0 + para.lineSpacing)
        }
        paragraphStyle.paragraphSpacingBefore = CGFloat(para.spaceBefore)
        paragraphStyle.paragraphSpacing = CGFloat(para.spaceAfter)

        // CRITICAL: attach textBlock to paragraph style for table cells
        if let cellBlock = cellBlock {
            paragraphStyle.textBlocks = [cellBlock]
        }

        // List paragraph setup — marker glyph is injected as text (NSTextList
        // alone does not render markers in modern AppKit; see research notes).
        // Format: `\t{marker}\t{content}`. Marker column is right-aligned so
        // bullets and multi-digit numbers both end at the same x position,
        // leaving a consistent small gap before the content.
        var listMarkerPrefix: NSAttributedString? = nil
        if let list = para.list {
            let textList = UDFListMapping.makeTextList(list)
            paragraphStyle.textLists = [textList]
            let textIndent = max(paragraphStyle.headIndent, 18)
            let markerColumn = max(0, textIndent - 4)
            paragraphStyle.headIndent = textIndent
            paragraphStyle.firstLineHeadIndent = 0
            paragraphStyle.tabStops = [
                NSTextTab(textAlignment: .right, location: markerColumn, options: [:]),
                NSTextTab(textAlignment: .left, location: textIndent, options: [:]),
            ]

            let itemNumber = counters.nextItemNumber(for: list)
            let marker = textList.marker(forItemNumber: itemNumber)
            var prefixAttrs = defaultAttributes()
            prefixAttrs[.paragraphStyle] = paragraphStyle
            addListAttributes(para.list, to: &prefixAttrs)
            listMarkerPrefix = NSAttributedString(string: "\t\(marker)\t", attributes: prefixAttrs)
        }

        if para.list == nil && !para.tabStops.isEmpty {
            paragraphStyle.tabStops = para.tabStops.map {
                NSTextTab(textAlignment: .left, location: CGFloat($0), options: [:])
            }
        }

        // Build attributed content for this paragraph
        let paraStr = NSMutableAttributedString()

        if let prefix = listMarkerPrefix {
            paraStr.append(prefix)
        }

        if para.runs.isEmpty {
            // Empty paragraph still needs at least a space for table cells to render
            var attrs = defaultAttributes()
            attrs[.paragraphStyle] = paragraphStyle
            addListAttributes(para.list, to: &attrs)
            paraStr.append(NSAttributedString(string: cellBlock != nil ? " " : "", attributes: attrs))
        } else {
            for (index, run) in para.runs.enumerated() {
                switch run {
                case .text(let textRun):
                    var attrs = attributesFor(style: textRun.style)
                    attrs[.paragraphStyle] = paragraphStyle
                    addListAttributes(para.list, to: &attrs)
                    // Parsed runs include the CDATA paragraph separator `\n`; we
                    // emit it ourselves below, so strip from the final run only.
                    var text = textRun.text
                    if index == para.runs.count - 1, text.hasSuffix("\n") {
                        text.removeLast()
                    }
                    paraStr.append(NSAttributedString(string: text, attributes: attrs))

                case .image(let imageRun):
                    let attachment = NSTextAttachment()
                    if let imageData = Data(base64Encoded: imageRun.data, options: .ignoreUnknownCharacters) {
                        attachment.image = udfDecodeImage(imageData)
                    }
                    attachment.bounds = NSRect(
                        x: 0, y: 0,
                        width: CGFloat(imageRun.width),
                        height: CGFloat(imageRun.height)
                    )
                    let imgStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
                    imgStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: imgStr.length))
                    if !imageRun.data.isEmpty {
                        imgStr.addAttribute(.udfImageData, value: imageRun.data, range: NSRange(location: 0, length: imgStr.length))
                    }
                    paraStr.append(imgStr)

                case .tab(let tabRun):
                    var attrs = attributesFor(style: tabRun.style)
                    attrs[.paragraphStyle] = paragraphStyle
                    paraStr.append(NSAttributedString(string: "\t", attributes: attrs))
                }
            }
        }

        // CRITICAL: every paragraph must end with \n and the \n must carry the same paragraphStyle
        // This is what makes NSTextTable actually render cells properly
        var newlineAttrs = defaultAttributes()
        newlineAttrs[.paragraphStyle] = paragraphStyle
        paraStr.append(NSAttributedString(string: "\n", attributes: newlineAttrs))

        result.append(paraStr)
    }

    // MARK: - Table

    private static func appendTable(_ table: Table, to result: NSMutableAttributedString) {
        appendTable(table, to: result, ancestors: [])
    }

    private static func appendTable(_ table: Table, to result: NSMutableAttributedString,
                                    ancestors: [NSTextTableBlock]) {
        let nsTable = NSTextTable()
        let cellCounts = table.rows.map { max($0.cells.count, 1) } + [max(table.columns, 1)]
        let grid = TableGrid.units(forRowCellCounts: cellCounts)
        nsTable.numberOfColumns = grid
        nsTable.hidesEmptyCells = false
        nsTable.setContentWidth(100, type: .percentageValueType)

        var currentRow = 0
        for row in table.rows {
            // Fall back to colspan*100 so programmatically-built cells (legacy/tests)
            // that set colspan but no width still render at the right span.
            let widths = row.cells.map { $0.width ?? Double(max($0.colspan, 1)) * 100 }
            let total = max(widths.reduce(0, +), 1)
            var col = 0
            for (idx, cell) in row.cells.enumerated() {
                let span = (idx == row.cells.count - 1)
                    ? max(grid - col, 1)
                    : max(Int((widths[idx] / total * Double(grid)).rounded()), 1)
                let block = NSTextTableBlock(table: nsTable, startingRow: currentRow, rowSpan: 1,
                                             startingColumn: col, columnSpan: span)
                configureBlock(block, cell: cell, row: row)
                let chain = ancestors + [block]
                let meta = cellMetaAttributes(table: table, row: row, cell: cell)
                var emitted = false
                for content in cell.content {
                    switch content {
                    case .paragraph(let para):
                        appendCellParagraph(para, to: result, blocks: chain, meta: meta); emitted = true
                    case .table(let inner):
                        appendTable(inner, to: result, ancestors: chain); emitted = true
                    case .pageBreak: break
                    }
                }
                if !emitted { appendCellParagraph(Paragraph(), to: result, blocks: chain, meta: meta) }
                col += span
            }
            currentRow += 1
        }
    }

    /// Build the UDF table/row/cell metadata that NSTextTable cannot represent,
    /// stashed on every cell paragraph so the table round-trips through save.
    private static func cellMetaAttributes(table: Table, row: TableRow, cell: TableCell) -> [NSAttributedString.Key: Any] {
        var m: [NSAttributedString.Key: Any] = [:]
        m[.udfTableName] = table.name
        if let a = table.align { m[.udfTableAlign] = a }
        if let w = table.width { m[.udfTableWidth] = w }
        if let cp = table.cellpadding { m[.udfTableCellpadding] = cp }
        if let cs = table.cellspacing { m[.udfTableCellspacing] = cs }
        if !table.columnWidths.isEmpty {
            m[.udfColumnSpans] = table.columnWidths.map { String(Int($0.rounded())) }.joined(separator: ",")
        }
        m[.udfTableBorderName] = table.border.name
        m[.udfTableBorderStyle] = table.border.style
        if let bw = table.borderWidth { m[.udfTableBorderWidth] = bw }
        if let bc = table.borderColor { m[.udfTableBorderColor] = Int(bc) }
        if let bs = table.borderSpec { m[.udfTableBorderSpec] = bs }
        m[.udfRowName] = row.name
        m[.udfRowType] = row.rowType
        // Cell border (preserves exact borderColor=0 that opaque rendering loses).
        m[.udfBorderName] = cell.border.name
        m[.udfBorderStyle] = cell.border.style
        m[.udfBorderWidth] = cell.borderWidth
        m[.udfBorderColor] = Int(cell.borderColor)
        m[.udfBorderSpec] = cell.borderSpec
        m[.udfFillColor] = Int(cell.fillColor)
        if let w = cell.width { m[.udfCellWidth] = w }
        if let hm = row.heightMin { m[.udfRowHeightMin] = hm }
        if row.height > 0 { m[.udfRowHeight] = row.height }
        return m
    }

    /// Render one paragraph of a cell, carrying the full `textBlocks` chain.
    private static func appendCellParagraph(_ para: Paragraph, to result: NSMutableAttributedString,
                                            blocks: [NSTextTableBlock],
                                            meta: [NSAttributedString.Key: Any] = [:]) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.textBlocks = blocks

        let str = NSMutableAttributedString()
        for run in para.runs {
            switch run {
            case .text(let textRun):
                var attrs = attributesFor(style: textRun.style)
                attrs[.paragraphStyle] = paragraphStyle
                str.append(NSAttributedString(string: textRun.text, attributes: attrs))
            case .tab(let tabRun):
                var attrs = attributesFor(style: tabRun.style)
                attrs[.paragraphStyle] = paragraphStyle
                str.append(NSAttributedString(string: "\t", attributes: attrs))
            case .image(let imageRun):
                let attachment = NSTextAttachment()
                if let data = Data(base64Encoded: imageRun.data, options: .ignoreUnknownCharacters) { attachment.image = udfDecodeImage(data) }
                attachment.bounds = NSRect(x: 0, y: 0, width: CGFloat(imageRun.width), height: CGFloat(imageRun.height))
                let imgStr = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
                imgStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: imgStr.length))
                if !imageRun.data.isEmpty {
                    imgStr.addAttribute(.udfImageData, value: imageRun.data, range: NSRange(location: 0, length: imgStr.length))
                }
                str.append(imgStr)
            }
        }
        // Empty paragraph: a space so the cell renders (matches single-level behaviour).
        if str.length == 0 {
            var attrs = defaultAttributes()
            attrs[.paragraphStyle] = paragraphStyle
            str.append(NSAttributedString(string: " ", attributes: attrs))
        }
        var newlineAttrs = defaultAttributes()
        newlineAttrs[.paragraphStyle] = paragraphStyle
        str.append(NSAttributedString(string: "\n", attributes: newlineAttrs))
        if !meta.isEmpty {
            str.addAttributes(meta, range: NSRange(location: 0, length: str.length))
        }
        result.append(str)
    }

    /// Per-cell block setup: padding, borders, fill, and optional minimum height.
    /// Column width is now encoded in the span (numberOfColumns / grid), so the
    /// old per-block percentage is omitted.
    private static func configureBlock(_ block: NSTextTableBlock, cell: TableCell, row: TableRow) {
        for edge: NSRectEdge in [.minX, .maxX, .minY, .maxY] {
            block.setWidth(3, type: .absoluteValueType, for: .padding, edge: edge)
        }
        configureBorders(block, cell: cell)
        if cell.fillColor != 16777215 && cell.fillColor != -1 {
            block.backgroundColor = NSColor(argbInt32: cell.fillColor)
        }
        if let hm = row.heightMin, hm > 0 {
            block.setValue(CGFloat(hm), type: .absoluteValueType, for: .minimumHeight)
        }
    }

    // MARK: - Borders

    private static func configureBorders(_ block: NSTextTableBlock, cell: TableCell) {
        // Görünürlük kuralı UDFKit'te saf fonksiyonda (borderNone / width>0 /
        // near-white değil / spec biti). borderColor alpha'sı yok sayılır:
        // borderColor=0 → opak siyah (resmi editör davranışı).
        let edges = visibleBorderEdges(
            borderName: cell.border.name,
            borderWidth: cell.borderWidth,
            borderSpec: cell.borderSpec,
            borderColor: cell.borderColor
        )
        let comps = argbToComponents(cell.borderColor)
        let borderColor = NSColor(srgbRed: CGFloat(comps.r), green: CGFloat(comps.g),
                                  blue: CGFloat(comps.b), alpha: 1.0)
        let borderWidth = CGFloat(cell.borderWidth)

        func apply(_ visible: Bool, _ edge: NSRectEdge) {
            if visible {
                block.setBorderColor(borderColor, for: edge)
                block.setWidth(borderWidth, type: .absoluteValueType, for: .border, edge: edge)
            } else {
                // Görünmez kenar: renk de atama, genişliği sıfırla (hairline'ı önler).
                block.setWidth(0, type: .absoluteValueType, for: .border, edge: edge)
            }
        }
        apply(edges.top, .minY)     // top=1
        apply(edges.right, .maxX)   // right=2
        apply(edges.bottom, .maxY)  // bottom=4
        apply(edges.left, .minX)    // left=8
    }

    // MARK: - Helpers

    private static func attributesFor(style: TextStyle) -> [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [:]

        var font = NSFont(name: style.fontFamily, size: CGFloat(style.fontSize))
            ?? NSFont.systemFont(ofSize: CGFloat(style.fontSize))

        if style.bold || style.italic {
            var traits: NSFontTraitMask = []
            if style.bold { traits.insert(.boldFontMask) }
            if style.italic { traits.insert(.italicFontMask) }
            font = NSFontManager.shared.convert(font, toHaveTrait: traits)
        }
        attrs[.font] = font

        if style.underline {
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        if style.strikethrough {
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }

        // Preserve the original family verbatim — AppKit may have substituted a
        // system fallback above when the family isn't installed on this machine.
        attrs[.udfFontFamily] = style.fontFamily

        attrs[.foregroundColor] = NSColor(argbInt32: style.color)
        if style.backgroundColor != -1 {
            attrs[.backgroundColor] = NSColor(argbInt32: style.backgroundColor)
        }

        return attrs
    }

    private static func addListAttributes(_ list: ListProperties?, to attrs: inout [NSAttributedString.Key: Any]) {
        guard let list = list else { return }
        attrs[.udfListType] = list.type.rawValue
        attrs[.udfListLevel] = list.level
        if let nt = list.numberType { attrs[.udfNumberType] = nt }
        if let bt = list.bulletType { attrs[.udfBulletType] = bt }
        if let lid = list.listId { attrs[.udfListId] = lid }
    }

    private static func defaultAttributes() -> [NSAttributedString.Key: Any] {
        return attributesFor(style: .default)
    }
}
