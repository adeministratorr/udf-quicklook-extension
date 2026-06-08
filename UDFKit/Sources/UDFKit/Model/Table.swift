import Foundation

public struct BorderStyle: Sendable, Equatable, Codable {
    public var name: String   // "borderCell", "borderTable", "borderNone"
    public var style: String  // "borderStyle-solid", "borderStyle-none"

    public init(name: String = "borderCell", style: String = "borderStyle-solid") {
        self.name = name
        self.style = style
    }

    public static let `default` = BorderStyle()
}

public enum VerticalAlignment: String, Sendable, Codable {
    case top
    case middle
    case bottom
}

public struct TableCell: Sendable, Equatable {
    public var colspan: Int
    public var rowspan: Int
    public var verticalAlign: VerticalAlignment
    public var fillColor: Int32       // ARGB int32
    public var border: BorderStyle
    public var borderWidth: Double
    public var borderColor: Int32     // ARGB int32
    public var borderSpec: Int        // bitmask: top=1, right=2, bottom=4, left=8
    public var width: Double?         // relative width (from row/table columnSpans)
    public var content: [BlockElement]

    public init(
        colspan: Int = 1,
        rowspan: Int = 1,
        verticalAlign: VerticalAlignment = .top,
        fillColor: Int32 = 16777215,  // white (unsigned)
        border: BorderStyle = .default,
        borderWidth: Double = 0.5,
        borderColor: Int32 = 0,
        borderSpec: Int = 15,         // all sides
        width: Double? = nil,
        content: [BlockElement] = []
    ) {
        self.colspan = colspan
        self.rowspan = rowspan
        self.verticalAlign = verticalAlign
        self.fillColor = fillColor
        self.border = border
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.borderSpec = borderSpec
        self.width = width
        self.content = content
    }
}

public struct TableRow: Sendable, Equatable {
    public var name: String
    public var rowType: String  // "dataRow"
    public var height: Double        // actual height (from table rowSpans)
    public var heightMin: Double?    // user-set minimum (height_min)
    public var border: BorderStyle
    public var valign: String?  // row vertical align token (tolerated; never emitted)
    public var cells: [TableCell]

    public init(
        name: String = "row1",
        rowType: String = "dataRow",
        height: Double = 0,
        heightMin: Double? = nil,
        border: BorderStyle = .default,
        valign: String? = nil,
        cells: [TableCell] = []
    ) {
        self.name = name
        self.rowType = rowType
        self.height = height
        self.heightMin = heightMin
        self.border = border
        self.valign = valign
        self.cells = cells
    }
}

public struct Table: Sendable, Equatable {
    public var name: String         // "Sabit"
    public var columns: Int
    public var columnWidths: [Double] // relative widths
    public var border: BorderStyle
    public var rows: [TableRow]
    // Optional table-level attributes carried verbatim for official-editor
    // fidelity. When set, the serializer writes them on `<table>` and only
    // emits per-cell border attributes for cells that differ from the table.
    public var align: String?           // "center"
    public var width: String?           // "16.00cm"
    public var cellpadding: Double?
    public var cellspacing: Double?
    public var borderWidth: Double?     // table-level border geometry
    public var borderColor: Int32?
    public var borderSpec: Int?

    public init(
        name: String = "Sabit",
        columns: Int = 0,
        columnWidths: [Double] = [],
        border: BorderStyle = .default,
        rows: [TableRow] = [],
        align: String? = nil,
        width: String? = nil,
        cellpadding: Double? = nil,
        cellspacing: Double? = nil,
        borderWidth: Double? = nil,
        borderColor: Int32? = nil,
        borderSpec: Int? = nil
    ) {
        self.name = name
        self.columns = columns
        self.columnWidths = columnWidths
        self.border = border
        self.rows = rows
        self.align = align
        self.width = width
        self.cellpadding = cellpadding
        self.cellspacing = cellspacing
        self.borderWidth = borderWidth
        self.borderColor = borderColor
        self.borderSpec = borderSpec
    }
}
