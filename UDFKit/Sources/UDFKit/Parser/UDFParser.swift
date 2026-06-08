import Foundation
import ZIPFoundation

public enum UDFParserError: Error, LocalizedError {
    case missingContentXml
    case missingTemplateElement
    case missingContentElement
    case invalidXml(String)
    case zipError(String)

    public var errorDescription: String? {
        switch self {
        case .missingContentXml:
            return "UDF file does not contain content.xml"
        case .missingTemplateElement:
            return "Missing <template> root element"
        case .missingContentElement:
            return "Missing <content> element"
        case .invalidXml(let msg):
            return "Invalid XML: \(msg)"
        case .zipError(let msg):
            return "ZIP error: \(msg)"
        }
    }
}

public struct UDFParser {

    public init() {}

    /// Parse a UDF file from raw Data (ZIP archive).
    public func parse(from data: Data) throws -> UDFDocument {
        // Extract content.xml from ZIP
        let archive: Archive
        do {
            archive = try Archive(data: data, accessMode: .read)
        } catch {
            throw UDFParserError.zipError("Failed to open ZIP archive: \(error)")
        }

        var xmlData = Data()
        guard let entry = archive["content.xml"] else {
            throw UDFParserError.missingContentXml
        }
        _ = try archive.extract(entry) { chunk in
            xmlData.append(chunk)
        }

        guard let xmlString = String(data: xmlData, encoding: .utf8) else {
            throw UDFParserError.invalidXml("content.xml is not valid UTF-8")
        }

        // Parse XML DOM
        let xmlDoc = try XMLDocument(xmlString: xmlString, options: [])

        // Find <template> root
        guard let templateEl = xmlDoc.rootElement(), templateEl.name == "template" else {
            throw UDFParserError.missingTemplateElement
        }

        // Extract CDATA text from <content>
        guard let contentEl = findElement(templateEl, named: "content") else {
            throw UDFParserError.missingContentElement
        }
        let cdataText = contentEl.stringValue ?? ""

        // Parse page format
        let propertiesEl = findElement(templateEl, named: "properties")
        let pages = propertiesEl != nil ? parsePageFormat(propertiesEl!) : .default

        // Parse block elements (header + body + footer, in document order)
        let elementsEl = findElement(templateEl, named: "elements")
        let parsed = elementsEl != nil ? parseElements(elementsEl!, cdataText: cdataText) : ParsedElements()

        let formatId = templateEl.attribute(forName: "format_id")?.stringValue ?? "1.8"
        let resolver = elementsEl?.attribute(forName: "resolver")?.stringValue ?? "hvl-default"
        let styles = parseStyles(templateEl)

        return UDFDocument(
            pages: pages,
            header: parsed.header,
            body: parsed.body,
            footer: parsed.footer,
            footerPageNumber: parsed.footerPageNumber,
            formatId: formatId,
            resolver: resolver,
            styles: styles
        )
    }

    private func parseStyles(_ templateEl: XMLElement) -> [DocumentStyle] {
        guard let stylesEl = findElement(templateEl, named: "styles") else {
            return DocumentStyle.defaults
        }
        var out: [DocumentStyle] = []
        for styleEl in childElements(stylesEl, named: "style") {
            let name = styleEl.attribute(forName: "name")?.stringValue ?? ""
            var attrs: [StyleAttribute] = []
            for attr in styleEl.attributes ?? [] {
                guard let an = attr.name, an != "name", let av = attr.stringValue else { continue }
                attrs.append(StyleAttribute(name: an, value: av))
            }
            out.append(DocumentStyle(name: name, attributes: attrs))
        }
        return out.isEmpty ? DocumentStyle.defaults : out
    }

    private struct ParsedElements {
        var header: [BlockElement] = []
        var body: [BlockElement] = []
        var footer: [BlockElement] = []
        var footerPageNumber: FooterPageNumber? = nil
    }

    // MARK: - Page Format

    private func parsePageFormat(_ propertiesEl: XMLElement) -> PageFormat {
        guard let pf = findElement(propertiesEl, named: "pageFormat") else {
            return .default
        }
        return PageFormat(
            mediaSizeName: attrInt(pf, "mediaSizeName", 1),
            leftMargin: attrFloat(pf, "leftMargin", PageFormat.default.leftMargin),
            rightMargin: attrFloat(pf, "rightMargin", PageFormat.default.rightMargin),
            topMargin: attrFloat(pf, "topMargin", PageFormat.default.topMargin),
            bottomMargin: attrFloat(pf, "bottomMargin", PageFormat.default.bottomMargin),
            paperOrientation: attrInt(pf, "paperOrientation", 1),
            headerFOffset: attrFloat(pf, "headerFOffset", PageFormat.default.headerFOffset),
            footerFOffset: attrFloat(pf, "footerFOffset", PageFormat.default.footerFOffset)
        )
    }

    // MARK: - Elements

    private func parseElements(_ elementsEl: XMLElement, cdataText: String) -> ParsedElements {
        var result = ParsedElements()
        guard let children = elementsEl.children else { return result }

        for child in children {
            guard let el = child as? XMLElement else { continue }
            switch el.name {
            case "paragraph":
                result.body.append(.paragraph(parseParagraph(el, cdataText: cdataText)))
            case "table":
                result.body.append(.table(parseTable(el, cdataText: cdataText)))
            case "header":
                result.header = parseSectionChildren(el, cdataText: cdataText)
            case "footer":
                result.footer = parseSectionChildren(el, cdataText: cdataText)
                result.footerPageNumber = parseFooterPageNumber(el)
            case "page-break":
                result.body.append(.pageBreak)
            default:
                break
            }
        }
        return result
    }

    /// Parse the `<paragraph>` / `<table>` children of a header/footer element.
    private func parseSectionChildren(_ el: XMLElement, cdataText: String) -> [BlockElement] {
        var blocks: [BlockElement] = []
        guard let children = el.children else { return blocks }
        for child in children {
            guard let childEl = child as? XMLElement else { continue }
            switch childEl.name {
            case "paragraph":
                blocks.append(.paragraph(parseParagraph(childEl, cdataText: cdataText)))
            case "table":
                blocks.append(.table(parseTable(childEl, cdataText: cdataText)))
            default:
                break
            }
        }
        return blocks
    }

    /// Extract footer `pageNumber-*` metadata into FooterPageNumber. Only
    /// meaningful when the footer element itself carries those attributes.
    private func parseFooterPageNumber(_ el: XMLElement) -> FooterPageNumber? {
        let known: Set<String> = [
            "pageNumber-spec", "pageNumber-fontFace", "pageNumber-fontSize",
            "pageNumber-fontBold", "pageNumber-fontItalic", "pageNumber-color",
            "pageNumber-foreStr", "pageNumber-pageStartNumStr",
        ]
        let boundaryKeys: Set<String> = ["color-boundary", "stroke-boundary"]

        // Only emit a FooterPageNumber if at least one page-number attr exists.
        let hasAnyPageNumberAttr = known.contains { el.attribute(forName: $0) != nil }
        guard hasAnyPageNumberAttr || boundaryKeys.contains(where: { el.attribute(forName: $0) != nil }) else {
            return nil
        }

        var extras: [String: String] = [:]
        if let attrs = el.attributes {
            for attr in attrs {
                guard let name = attr.name else { continue }
                if known.contains(name) { continue }
                if let val = attr.stringValue { extras[name] = val }
            }
        }

        return FooterPageNumber(
            spec: attrStr(el, "pageNumber-spec"),
            fontFace: attrStr(el, "pageNumber-fontFace", "Times New Roman"),
            fontSize: attrFloat(el, "pageNumber-fontSize", 11),
            fontBold: attrBool(el, "pageNumber-fontBold"),
            fontItalic: attrBool(el, "pageNumber-fontItalic"),
            color: attrInt32(el, "pageNumber-color", -16777216),
            foreStr: attrStr(el, "pageNumber-foreStr"),
            pageStartNumStr: attrStr(el, "pageNumber-pageStartNumStr"),
            extraAttributes: extras
        )
    }

    // MARK: - Paragraph

    private func parseParagraph(_ el: XMLElement, cdataText: String) -> Paragraph {
        var runs: [InlineElement] = []
        var emptyContentStyle: TextStyle? = nil

        if let children = el.children {
            for child in children {
                guard let childEl = child as? XMLElement else { continue }
                switch childEl.name {
                case "content":
                    // Empty-paragraph placeholders are `length="1"` content
                    // pointing at the paragraph's own `\u{200B}` slot. Some
                    // converters emit a buggy `startOffset="0" length="1"` that
                    // points at the first CDATA character instead. Either way,
                    // capture the placeholder's font so the empty line round-trips
                    // with the same family/size the official editor writes.
                    let startOffset = attrInt(childEl, "startOffset", -1)
                    let length = attrInt(childEl, "length", -1)
                    let run = parseTextRun(childEl, cdataText: cdataText)
                    let isPlaceholder = (startOffset == 0 && length == 1
                        && el.childCount == 1
                        && el.attribute(forName: "Bulleted") == nil
                        && el.attribute(forName: "Numbered") == nil)
                    if isPlaceholder || run.text.isEmpty {
                        if emptyContentStyle == nil { emptyContentStyle = run.style }
                        break
                    }
                    runs.append(.text(run))
                case "image":
                    runs.append(.image(parseImageRun(childEl)))
                case "tab":
                    let style = TextStyle(
                        fontFamily: attrStr(childEl, "family", TextStyle.default.fontFamily),
                        fontSize: attrFloat(childEl, "size", TextStyle.default.fontSize),
                        bold: attrBool(childEl, "bold"),
                        italic: attrBool(childEl, "italic"),
                        underline: attrBool(childEl, "underline"),
                        strikethrough: attrBool(childEl, "strikethrough"),
                        color: attrInt32(childEl, "foreground", TextStyle.default.color),
                        backgroundColor: attrInt32(childEl, "background", TextStyle.default.backgroundColor)
                    )
                    runs.append(.tab(TabRun(style: style)))
                default:
                    break
                }
            }
        }

        // Filter out text runs that are empty after removing zero-width spaces
        runs = runs.filter { element in
            if case .text(let run) = element, run.text.isEmpty {
                return false
            }
            return true
        }

        var paragraph = Paragraph(
            alignment: parseAlignment(el.attribute(forName: "Alignment")?.stringValue),
            leftIndent: attrFloat(el, "LeftIndent"),
            rightIndent: attrFloat(el, "RightIndent"),
            firstLineIndent: attrFloat(el, "FirstLineIndent"),
            lineSpacing: attrFloat(el, "LineSpacing"),
            spaceBefore: attrFloat(el, "SpaceAbove"),
            spaceAfter: attrFloat(el, "SpaceBelow"),
            runs: runs
        )

        if let tabSet = el.attribute(forName: "TabSet")?.stringValue, !tabSet.isEmpty {
            paragraph.tabStops = tabSet
                .split(whereSeparator: { $0 == "," || $0 == ";" })
                .compactMap { Double($0.split(separator: ":").first.map(String.init) ?? "") }
        }

        // List properties
        let isNumbered = attrBool(el, "Numbered")
        let isBulleted = attrBool(el, "Bulleted")
        if isNumbered || isBulleted {
            var list = ListProperties(
                type: isNumbered ? .numbered : .bulleted,
                level: attrInt(el, "ListLevel")
            )
            if let nt = el.attribute(forName: "NumberType")?.stringValue {
                list.numberType = nt
            }
            if let bt = el.attribute(forName: "BulletType")?.stringValue {
                list.bulletType = bt
            }
            if let lid = el.attribute(forName: "ListId")?.stringValue, !lid.isEmpty {
                list.listId = Int(lid)
            }
            paragraph.list = list
        }

        if runs.isEmpty {
            paragraph.emptyContentStyle = emptyContentStyle
        }

        return paragraph
    }

    // MARK: - Inline Elements

    private func parseTextRun(_ el: XMLElement, cdataText: String) -> TextRun {
        let startOffset = attrInt(el, "startOffset")
        let length = attrInt(el, "length")

        var text = runeSubstring(cdataText, startOffset: startOffset, length: length)

        // Filter out zero-width space placeholder used for empty paragraphs
        text = text.replacingOccurrences(of: "\u{200B}", with: "")

        let style = TextStyle(
            fontFamily: attrStr(el, "family", TextStyle.default.fontFamily),
            fontSize: attrFloat(el, "size", TextStyle.default.fontSize),
            bold: attrBool(el, "bold"),
            italic: attrBool(el, "italic"),
            underline: attrBool(el, "underline"),
            strikethrough: attrBool(el, "strikethrough"),
            color: attrInt32(el, "foreground", TextStyle.default.color),
            backgroundColor: attrInt32(el, "background", TextStyle.default.backgroundColor)
        )

        return TextRun(text: text, style: style)
    }

    private func parseImageRun(_ el: XMLElement) -> ImageRun {
        return ImageRun(
            data: attrStr(el, "imageData"),
            width: attrFloat(el, "width"),
            height: attrFloat(el, "height")
        )
    }

    // MARK: - Table

    /// Table-level border geometry that bare cells inherit (genuine files often
    /// define the border only on `<table>` and leave the cells empty).
    private struct InheritedBorder {
        var name: String?
        var style: String?
        var width: Double?
        var color: Int32?
        var spec: Int?
    }

    private func parseTable(_ el: XMLElement, cdataText: String) -> Table {
        let inherited = InheritedBorder(
            name: attrStrOpt(el, "border"),
            style: attrStrOpt(el, "borderStyle"),
            width: attrFloatOpt(el, "borderWidth"),
            color: attrInt32Opt(el, "borderColor"),
            spec: attrIntOpt(el, "borderSpec")
        )
        let columnCount = attrInt(el, "columnCount", 0)
        var defaultWidths = attrStr(el, "columnSpans")
            .split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        let cols = max(columnCount, defaultWidths.count)
        while defaultWidths.count < cols { defaultWidths.append(100.0) }
        let rowHeights = attrStr(el, "rowSpans")
            .split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        var rows: [TableRow] = []
        for (i, rowEl) in childElements(el, named: "row").enumerated() {
            var row = parseTableRow(rowEl, cdataText: cdataText, inherited: inherited, defaultWidths: defaultWidths)
            if i < rowHeights.count { row.height = rowHeights[i] }
            rows.append(row)
        }
        return Table(
            name: attrStr(el, "tableName", "Sabit"),
            columns: max(cols, 1),
            columnWidths: defaultWidths,
            border: parseBorderStyle(el),
            rows: rows,
            align: attrStrOpt(el, "align"),
            width: attrStrOpt(el, "width"),
            cellpadding: attrFloatOpt(el, "cellpadding"),
            cellspacing: attrFloatOpt(el, "cellspacing"),
            borderWidth: inherited.width,
            borderColor: inherited.color,
            borderSpec: inherited.spec
        )
    }

    private func parseTableRow(_ el: XMLElement, cdataText: String,
                               inherited: InheritedBorder, defaultWidths: [Double]) -> TableRow {
        let rowWidths = attrStr(el, "columnSpans")
            .split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        var cells: [TableCell] = []
        for (i, cellEl) in childElements(el, named: "cell").enumerated() {
            var cell = parseTableCell(cellEl, cdataText: cdataText, inherited: inherited)
            let w = !rowWidths.isEmpty
                ? (i < rowWidths.count ? rowWidths[i] : 100.0)
                : (i < defaultWidths.count ? defaultWidths[i] : 100.0)
            cell.width = cell.width ?? w
            cells.append(cell)
        }
        return TableRow(
            name: attrStr(el, "rowName", "row1"),
            rowType: attrStr(el, "rowType", "dataRow"),
            height: attrFloat(el, "height"),
            heightMin: attrFloatOpt(el, "height_min"),
            border: parseBorderStyle(el),
            valign: attrStrOpt(el, "valign"),
            cells: cells
        )
    }

    private func parseTableCell(_ el: XMLElement, cdataText: String, inherited: InheritedBorder) -> TableCell {
        var content: [BlockElement] = []
        if let children = el.children {
            for child in children {
                guard let childEl = child as? XMLElement else { continue }
                switch childEl.name {
                case "paragraph":
                    content.append(.paragraph(parseParagraph(childEl, cdataText: cdataText)))
                case "table":
                    content.append(.table(parseTable(childEl, cdataText: cdataText)))
                default:
                    break
                }
            }
        }

        // Inherit the table-level border when the cell defines none of its own.
        let borderName = attrStrOpt(el, "border") ?? inherited.name ?? BorderStyle.default.name
        let borderStyleStr = attrStrOpt(el, "borderStyle") ?? inherited.style ?? BorderStyle.default.style
        let borderWidth = attrFloatOpt(el, "borderWidth") ?? inherited.width ?? 0.5
        let borderColor = attrInt32Opt(el, "borderColor") ?? inherited.color ?? 0
        let borderSpec = attrIntOpt(el, "borderSpec") ?? inherited.spec ?? 15

        var cell = TableCell(
            colspan: attrInt(el, "colspan", 1),
            rowspan: attrInt(el, "rowspan", 1),
            verticalAlign: parseVerticalAlign(el.attribute(forName: "align")?.stringValue),
            fillColor: attrInt32(el, "fillColor", 16777215),
            border: BorderStyle(name: borderName, style: borderStyleStr),
            borderWidth: borderWidth,
            borderColor: borderColor,
            borderSpec: borderSpec,
            content: content
        )
        if cell.colspan > 1 { cell.width = Double(cell.colspan) * 100.0; cell.colspan = 1 }
        return cell
    }

    // MARK: - Helpers

    private func parseAlignment(_ value: String?) -> Alignment {
        switch value {
        case "1": return .center
        case "2": return .right
        case "3": return .justify
        default: return .left
        }
    }

    private func parseVerticalAlign(_ value: String?) -> VerticalAlignment {
        switch value {
        case "vcenter", "center", "middle": return .middle
        case "bottom": return .bottom
        default: return .top
        }
    }

    private func parseBorderStyle(_ el: XMLElement) -> BorderStyle {
        return BorderStyle(
            name: attrStr(el, "border", BorderStyle.default.name),
            style: attrStr(el, "borderStyle", BorderStyle.default.style)
        )
    }
}
