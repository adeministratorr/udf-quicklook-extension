import Foundation

public enum BlockElement: Sendable, Equatable {
    case paragraph(Paragraph)
    case table(Table)
    case pageBreak
}

/// Metadata controlling the optional page-number glyph that UYAP renders
/// inside a footer. Captured verbatim for round-tripping; values are
/// opaque strings because the native UDF renderer interprets them.
public struct FooterPageNumber: Sendable, Equatable {
    public var spec: String              // e.g. "BSP32_40"
    public var fontFace: String          // e.g. "Arial"
    public var fontSize: Double
    public var fontBold: Bool
    public var fontItalic: Bool
    public var color: Int32              // signed ARGB
    public var foreStr: String           // optional prefix text
    public var pageStartNumStr: String   // starting page-number offset

    /// Extra attributes (e.g. color-boundary, stroke-boundary) preserved so
    /// the serializer can emit them back unchanged.
    public var extraAttributes: [String: String]

    public init(
        spec: String = "",
        fontFace: String = "Times New Roman",
        fontSize: Double = 11,
        fontBold: Bool = false,
        fontItalic: Bool = false,
        color: Int32 = -16777216,
        foreStr: String = "",
        pageStartNumStr: String = "",
        extraAttributes: [String: String] = [:]
    ) {
        self.spec = spec
        self.fontFace = fontFace
        self.fontSize = fontSize
        self.fontBold = fontBold
        self.fontItalic = fontItalic
        self.color = color
        self.foreStr = foreStr
        self.pageStartNumStr = pageStartNumStr
        self.extraAttributes = extraAttributes
    }
}

/// One `<style>` definition from a document's `<styles>` block.
/// `attributes` preserves every non-`name` attribute verbatim in document
/// order so the serializer can re-emit it unchanged.
public struct StyleAttribute: Sendable, Equatable {
    public var name: String
    public var value: String
    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

public struct DocumentStyle: Sendable, Equatable {
    public var name: String
    public var attributes: [StyleAttribute]
    public init(name: String, attributes: [StyleAttribute]) {
        self.name = name
        self.attributes = attributes
    }

    /// The two styles UYAP emits for a fresh document (matches legacy output).
    public static let defaults: [DocumentStyle] = [
        DocumentStyle(name: "default", attributes: [
            .init(name: "description", value: "Geçerli"),
            .init(name: "family", value: "Dialog"),
            .init(name: "size", value: "12"),
            .init(name: "bold", value: "false"),
            .init(name: "italic", value: "false"),
            .init(name: "foreground", value: "-13421773"),
            .init(name: "FONT_ATTRIBUTE_KEY", value: "javax.swing.plaf.FontUIResource[family=Dialog,name=Dialog,style=plain,size=12]"),
        ]),
        DocumentStyle(name: "hvl-default", attributes: [
            .init(name: "family", value: "Times New Roman"),
            .init(name: "size", value: "12"),
            .init(name: "description", value: "Gövde"),
        ]),
    ]
}

public struct UDFDocument: Sendable, Equatable {
    public var pages: PageFormat
    public var header: [BlockElement]
    public var body: [BlockElement]
    public var footer: [BlockElement]
    public var footerPageNumber: FooterPageNumber?
    public var formatId: String
    public var resolver: String
    public var styles: [DocumentStyle]

    public init(
        pages: PageFormat = .default,
        header: [BlockElement] = [],
        body: [BlockElement] = [],
        footer: [BlockElement] = [],
        footerPageNumber: FooterPageNumber? = nil,
        formatId: String = "1.8",
        resolver: String = "hvl-default",
        styles: [DocumentStyle] = DocumentStyle.defaults
    ) {
        self.pages = pages
        self.header = header
        self.body = body
        self.footer = footer
        self.footerPageNumber = footerPageNumber
        self.formatId = formatId
        self.resolver = resolver
        self.styles = styles
    }
}
