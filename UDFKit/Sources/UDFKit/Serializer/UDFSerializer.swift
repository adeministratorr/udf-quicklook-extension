import Foundation
import ZIPFoundation

public enum UDFSerializerError: Error, LocalizedError {
    case zipCreationFailed

    public var errorDescription: String? {
        switch self {
        case .zipCreationFailed:
            return "Failed to create ZIP archive"
        }
    }
}

public struct UDFSerializer {

    public init() {}

    /// Serialize a UDFDocument to UDF file data (ZIP containing content.xml).
    public func serialize(_ doc: UDFDocument) throws -> Data {
        let cdataResult = buildCData(header: doc.header, body: doc.body, footer: doc.footer)
        let cdata = cdataResult.cdata
        let entries = cdataResult.entries

        // Build XML
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"
        xml += "<template format_id=\"\(escapeAttr(doc.formatId))\">\n"
        xml += "<content><![CDATA[\(cdata)]]></content>"
        xml += serializePageFormat(doc.pages)
        xml += "\n"
        xml += "<elements resolver=\"\(escapeAttr(doc.resolver))\">\n"

        var blockIdCounter = 0
        if !doc.header.isEmpty {
            xml += "<header>"
            xml += serializeBlocks(doc.header, entries: entries, blockIdCounter: &blockIdCounter)
            xml += "</header>\n"
        }
        xml += serializeBlocks(doc.body, entries: entries, blockIdCounter: &blockIdCounter)
        if !doc.footer.isEmpty {
            xml += "<footer\(serializeFooterAttributes(doc.footerPageNumber))>"
            xml += serializeBlocks(doc.footer, entries: entries, blockIdCounter: &blockIdCounter)
            xml += "</footer>\n"
        }

        xml += "</elements>\n"
        xml += serializeStyles(doc.styles)
        xml += "</template>"

        // Create ZIP
        guard let xmlData = xml.data(using: .utf8) else {
            throw UDFSerializerError.zipCreationFailed
        }

        let archive: Archive
        do {
            archive = try Archive(accessMode: .create)
        } catch {
            throw UDFSerializerError.zipCreationFailed
        }
        try archive.addEntry(
            with: "content.xml",
            type: .file,
            uncompressedSize: Int64(xmlData.count),
            compressionMethod: .deflate,
            provider: { position, size in
                let start = Int(position)
                let end = min(start + size, xmlData.count)
                return xmlData[start..<end]
            }
        )

        guard let archiveData = archive.data else {
            throw UDFSerializerError.zipCreationFailed
        }
        return archiveData
    }

    // MARK: - Footer Attributes

    private func serializeFooterAttributes(_ pn: FooterPageNumber?) -> String {
        guard let pn = pn else { return "" }
        var s = ""
        if !pn.spec.isEmpty { s += " pageNumber-spec=\"\(escapeAttr(pn.spec))\"" }
        s += " pageNumber-fontBold=\"\(pn.fontBold)\""
        s += " pageNumber-fontItalic=\"\(pn.fontItalic)\""
        s += " pageNumber-fontFace=\"\(escapeAttr(pn.fontFace))\""
        s += " pageNumber-fontSize=\"\(Int(pn.fontSize))\""
        s += " pageNumber-color=\"\(pn.color)\""
        s += " pageNumber-foreStr=\"\(escapeAttr(pn.foreStr))\""
        s += " pageNumber-pageStartNumStr=\"\(escapeAttr(pn.pageStartNumStr))\""
        // Preserve any extra attributes (color-boundary, stroke-boundary, etc.).
        for (key, value) in pn.extraAttributes.sorted(by: { $0.key < $1.key }) {
            s += " \(key)=\"\(escapeAttr(value))\""
        }
        return s
    }

    // MARK: - Styles

    private func serializeStyles(_ styles: [DocumentStyle]) -> String {
        let list = styles.isEmpty ? DocumentStyle.defaults : styles
        var xml = "<styles>"
        for style in list {
            xml += "<style name=\"\(escapeAttr(style.name))\""
            for attr in style.attributes {
                xml += " \(attr.name)=\"\(escapeAttr(attr.value))\""
            }
            xml += " />"
        }
        xml += "</styles>\n"
        return xml
    }

    // MARK: - Page Format

    private func serializePageFormat(_ pf: PageFormat) -> String {
        return "<properties>" +
            "<pageFormat" +
            " mediaSizeName=\"\(pf.mediaSizeName)\"" +
            " leftMargin=\"\(String(format: "%.2f", pf.leftMargin))\"" +
            " rightMargin=\"\(String(format: "%.2f", pf.rightMargin))\"" +
            " topMargin=\"\(String(format: "%.2f", pf.topMargin))\"" +
            " bottomMargin=\"\(String(format: "%.2f", pf.bottomMargin))\"" +
            " paperOrientation=\"\(pf.paperOrientation)\"" +
            " headerFOffset=\"\(String(format: "%.1f", pf.headerFOffset))\"" +
            " footerFOffset=\"\(String(format: "%.1f", pf.footerFOffset))\"" +
            " />" +
            "</properties>"
    }

    // MARK: - Block Serialization

    private func serializeBlocks(
        _ blocks: [BlockElement],
        entries: [OffsetEntry],
        blockIdCounter: inout Int
    ) -> String {
        var xml = ""
        for block in blocks {
            switch block {
            case .paragraph(let para):
                let id = blockIdCounter
                blockIdCounter += 1
                let blockEntries = entries.filter { $0.blockId == id }
                xml += serializeParagraph(para, blockEntries: blockEntries)
            case .table(let table):
                xml += serializeTable(table, entries: entries, blockIdCounter: &blockIdCounter)
            case .pageBreak:
                let id = blockIdCounter
                blockIdCounter += 1
                let inner = serializeParagraph(Paragraph(), blockEntries: entries.filter { $0.blockId == id })
                xml += "<page-break>\(inner.trimmingCharacters(in: .newlines))</page-break>\n"
            }
        }
        return xml
    }

    // MARK: - Paragraph

    private func serializeParagraph(_ para: Paragraph, blockEntries: [OffsetEntry]) -> String {
        var xml = "<paragraph"
        xml += " Alignment=\"\(para.alignment.rawValue)\""
        xml += " LeftIndent=\"\(String(format: "%.1f", para.leftIndent))\""
        xml += " RightIndent=\"\(String(format: "%.1f", para.rightIndent))\""

        if para.firstLineIndent != 0 {
            xml += " FirstLineIndent=\"\(String(format: "%.2f", para.firstLineIndent))\""
        }
        if para.lineSpacing != 0 {
            xml += " LineSpacing=\"\(String(format: "%.2f", para.lineSpacing))\""
        }
        if para.spaceBefore != 0 {
            xml += " SpaceAbove=\"\(String(format: "%.2f", para.spaceBefore))\""
        }
        if para.spaceAfter != 0 {
            xml += " SpaceBelow=\"\(String(format: "%.2f", para.spaceAfter))\""
        }

        if !para.tabStops.isEmpty {
            let tabSet = para.tabStops
                .map { String(format: "%.2f:0:0", $0) }
                .joined(separator: ",")
            xml += " TabSet=\"\(tabSet)\""
        }

        // List attributes
        if let list = para.list {
            if list.type == .numbered {
                xml += " Numbered=\"true\""
                if let nt = list.numberType {
                    xml += " NumberType=\"\(escapeAttr(nt))\""
                }
                if let lid = list.listId {
                    xml += " ListId=\"\(lid)\""
                }
                xml += " ListLevel=\"\(list.level)\""
            } else if list.type == .bulleted {
                xml += " Bulleted=\"true\""
                if let bt = list.bulletType {
                    xml += " BulletType=\"\(escapeAttr(bt))\""
                }
                if let lid = list.listId {
                    xml += " ListId=\"\(lid)\""
                }
                xml += " ListLevel=\"\(list.level)\""
            }
        }

        xml += ">"

        // UDE duplicates the paragraph's positional attributes onto each
        // <content> — but only when they are non-default (e.g. table cells with
        // LeftIndent). Plain body paragraphs keep bare <content>, matching UDE.
        let hasPositional = para.alignment != .left || para.leftIndent != 0 || para.rightIndent != 0
        let contentPositional = hasPositional
            ? " Alignment=\"\(para.alignment.rawValue)\"" +
              " LeftIndent=\"\(String(format: "%.1f", para.leftIndent))\"" +
              " RightIndent=\"\(String(format: "%.1f", para.rightIndent))\""
            : ""

        // Content / image elements
        if blockEntries.isEmpty {
            // Defensive fallback: CDataBuilder normally emits a real-offset
            // placeholder entry for empty paragraphs, so this should not run.
            let s = para.emptyContentStyle ?? TextStyle(fontFamily: "Times New Roman", fontSize: 10)
            xml += "<content\(contentPositional) startOffset=\"0\" length=\"1\"\(fontAttributes(s)) />"
        } else {
            for entry in blockEntries {
                switch entry.element {
                case .text(let run):
                    xml += "<content"
                    xml += contentPositional
                    xml += " startOffset=\"\(entry.startOffset)\""
                    xml += " length=\"\(entry.length)\""
                    xml += fontAttributes(run.style)
                    xml += " />"
                case .image(let img):
                    xml += "<image"
                    xml += " imageData=\"\(img.data)\""
                    xml += " startOffset=\"\(entry.startOffset)\""
                    xml += " length=\"1\""
                    xml += " width=\"\(String(format: "%.1f", img.width))\""
                    xml += " height=\"\(String(format: "%.1f", img.height))\""
                    xml += " />"
                case .tab(let run):
                    xml += "<tab"
                    xml += " startOffset=\"\(entry.startOffset)\""
                    xml += " length=\"1\""
                    xml += fontAttributes(run.style)
                    xml += " />"
                }
            }
        }

        xml += "</paragraph>\n"
        return xml
    }

    // MARK: - Table

    private func serializeTable(
        _ table: Table,
        entries: [OffsetEntry],
        blockIdCounter: inout Int
    ) -> String {
        var xml = "<table"
        xml += " tableName=\"\(escapeAttr(table.name))\""
        xml += " columnCount=\"\(table.columns)\""
        if let align = table.align { xml += " align=\"\(escapeAttr(align))\"" }
        if let cp = table.cellpadding { xml += " cellpadding=\"\(String(format: "%.1f", cp))\"" }
        if let cs = table.cellspacing { xml += " cellspacing=\"\(String(format: "%.1f", cs))\"" }
        xml += " border=\"\(escapeAttr(table.border.name))\""
        let spans = table.columnWidths.map { String(Int($0.rounded())) }
        xml += " columnSpans=\"\(spans.joined(separator: ","))\""
        if let width = table.width { xml += " width=\"\(escapeAttr(width))\"" }
        if table.rows.contains(where: { $0.height > 0 }) {
            let rs = table.rows.map { String(Int($0.height.rounded())) }
            xml += " rowSpans=\"\(rs.joined(separator: ","))\""
        }
        if table.borderSpec != nil || table.borderColor != nil || table.borderWidth != nil {
            xml += " borderStyle=\"\(escapeAttr(table.border.style))\""
            if let bw = table.borderWidth { xml += " borderWidth=\"\(String(format: "%.1f", bw))\"" }
            if let bc = table.borderColor { xml += " borderColor=\"\(bc)\"" }
            if let bs = table.borderSpec { xml += " borderSpec=\"\(bs)\"" }
        }
        xml += ">"
        for row in table.rows { xml += serializeRow(row, table: table, entries: entries, blockIdCounter: &blockIdCounter) }
        xml += "</table>\n"
        return xml
    }

    private func serializeRow(
        _ row: TableRow,
        table: Table,
        entries: [OffsetEntry],
        blockIdCounter: inout Int
    ) -> String {
        var xml = "<row"
        xml += " rowName=\"\(escapeAttr(row.name))\""
        xml += " rowType=\"\(escapeAttr(row.rowType))\""
        let rowWidths = row.cells.map { Int(($0.width ?? 100.0).rounded()) }
        let tableWidths = table.columnWidths.map { Int($0.rounded()) }
        if row.cells.count != table.columns || rowWidths != tableWidths {
            xml += " columnSpans=\"\(rowWidths.map(String.init).joined(separator: ","))\""
        }
        if let hm = row.heightMin { xml += " height_min=\"\(String(format: "%g", hm))\"" }
        xml += ">"
        for cell in row.cells { xml += serializeCell(cell, table: table, entries: entries, blockIdCounter: &blockIdCounter) }
        xml += "</row>"
        return xml
    }

    /// A cell whose border equals the table-level border is left bare so the
    /// border stays defined only on `<table>` (matching the official editor).
    private func cellInheritsTableBorder(_ cell: TableCell, _ table: Table) -> Bool {
        guard let tspec = table.borderSpec else { return false }
        return cell.borderSpec == tspec
            && cell.borderColor == (table.borderColor ?? cell.borderColor)
            && cell.borderWidth == (table.borderWidth ?? cell.borderWidth)
            && cell.border.name == table.border.name
            && cell.border.style == table.border.style
    }

    private func serializeCell(
        _ cell: TableCell,
        table: Table,
        entries: [OffsetEntry],
        blockIdCounter: inout Int
    ) -> String {
        var xml = "<cell"
        if cell.fillColor != 16777215 && cell.fillColor != -1 { xml += " fillColor=\"\(cell.fillColor)\"" }
        if cell.borderSpec != 0 && !cellInheritsTableBorder(cell, table) {
            xml += " border=\"\(escapeAttr(cell.border.name))\""
            xml += " borderWidth=\"\(String(format: "%.1f", cell.borderWidth))\""
            xml += " borderSpec=\"\(cell.borderSpec)\""
            xml += " borderColor=\"\(cell.borderColor)\""
            xml += " borderStyle=\"\(escapeAttr(cell.border.style))\""
        }
        xml += ">"
        xml += serializeBlocks(cell.content, entries: entries, blockIdCounter: &blockIdCounter)
        xml += "</cell>"
        return xml
    }

    // MARK: - Helpers

    private func fontAttributes(_ style: TextStyle) -> String {
        var s = " family=\"\(escapeAttr(style.fontFamily))\""
        s += " size=\"\(formatSize(style.fontSize))\""
        if style.bold { s += " bold=\"true\"" }
        if style.italic { s += " italic=\"true\"" }
        if style.underline { s += " underline=\"true\"" }
        if style.strikethrough { s += " strikethrough=\"true\"" }
        // Only emit foreground/background when non-default
        if style.color != -16777216 {
            s += " foreground=\"\(style.color)\""
        }
        if style.backgroundColor != -1 {
            s += " background=\"\(style.backgroundColor)\""
        }
        return s
    }

    /// Font sizes are integers in genuine UYAP files ("12", not "12.0").
    /// Keep a fractional form only when the size genuinely has one.
    private func formatSize(_ size: Double) -> String {
        if size == size.rounded() {
            return String(Int(size))
        }
        return String(format: "%g", size)
    }

    private func escapeAttr(_ value: String) -> String {
        return value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
