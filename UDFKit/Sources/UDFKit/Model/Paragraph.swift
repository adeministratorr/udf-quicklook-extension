import Foundation

public enum Alignment: Int, Sendable, Codable {
    case left = 0
    case center = 1
    case right = 2
    case justify = 3
}

public enum InlineElement: Sendable, Equatable {
    case text(TextRun)
    case image(ImageRun)
    case tab(TabRun)
}

public struct TabRun: Sendable, Equatable {
    public var style: TextStyle
    public init(style: TextStyle = .default) {
        self.style = style
    }
}

public struct TextRun: Sendable, Equatable {
    public var text: String
    public var style: TextStyle

    public init(text: String, style: TextStyle = .default) {
        self.text = text
        self.style = style
    }
}

public struct ImageRun: Sendable, Equatable {
    public var data: String   // base64-encoded image data
    public var width: Double  // points
    public var height: Double // points

    public init(data: String, width: Double, height: Double) {
        self.data = data
        self.width = width
        self.height = height
    }
}

public enum ListType: String, Sendable, Codable {
    case numbered
    case bulleted
}

public struct ListProperties: Sendable, Equatable {
    public var type: ListType
    public var numberType: String?  // e.g. "NUMBER_TYPE_NUMBER_DOT"
    public var bulletType: String?  // e.g. "BULLET_TYPE_ELLIPSE"
    public var level: Int           // 0-based nesting depth
    public var listId: Int?

    public init(
        type: ListType,
        numberType: String? = nil,
        bulletType: String? = nil,
        level: Int = 0,
        listId: Int? = nil
    ) {
        self.type = type
        self.numberType = numberType
        self.bulletType = bulletType
        self.level = level
        self.listId = listId
    }
}

public struct Paragraph: Sendable, Equatable {
    public var alignment: Alignment
    public var leftIndent: Double
    public var rightIndent: Double
    public var firstLineIndent: Double
    public var lineSpacing: Double    // offset from 1.0 (0.0=single, 0.5=1.5x, 1.0=double)
    public var spaceBefore: Double
    public var spaceAfter: Double
    public var runs: [InlineElement]
    public var list: ListProperties?
    public var tabStops: [Double]
    /// Font of the empty-paragraph placeholder (the `<content length="1">` slot
    /// pointing at the paragraph's `\u{200B}`). Captured so an empty line's font
    /// round-trips exactly the way the official editor writes it.
    public var emptyContentStyle: TextStyle?

    public init(
        alignment: Alignment = .left,
        leftIndent: Double = 0,
        rightIndent: Double = 0,
        firstLineIndent: Double = 0,
        lineSpacing: Double = 0,
        spaceBefore: Double = 0,
        spaceAfter: Double = 0,
        runs: [InlineElement] = [],
        list: ListProperties? = nil,
        tabStops: [Double] = [],
        emptyContentStyle: TextStyle? = nil
    ) {
        self.alignment = alignment
        self.leftIndent = leftIndent
        self.rightIndent = rightIndent
        self.firstLineIndent = firstLineIndent
        self.lineSpacing = lineSpacing
        self.spaceBefore = spaceBefore
        self.spaceAfter = spaceAfter
        self.runs = runs
        self.list = list
        self.tabStops = tabStops
        self.emptyContentStyle = emptyContentStyle
    }
}
