import Foundation

public struct TextStyle: Sendable, Equatable, Codable {
    public var fontFamily: String
    public var fontSize: Double
    public var bold: Bool
    public var italic: Bool
    public var underline: Bool
    public var strikethrough: Bool
    public var color: Int32           // signed ARGB int32
    public var backgroundColor: Int32 // signed ARGB int32

    public init(
        fontFamily: String = "Times New Roman",
        fontSize: Double = 12,
        bold: Bool = false,
        italic: Bool = false,
        underline: Bool = false,
        strikethrough: Bool = false,
        color: Int32 = -16777216,      // black (0xFF000000)
        backgroundColor: Int32 = -1    // white (0xFFFFFFFF)
    ) {
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.strikethrough = strikethrough
        self.color = color
        self.backgroundColor = backgroundColor
    }

    public static let `default` = TextStyle()
}
