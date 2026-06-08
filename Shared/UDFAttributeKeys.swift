import AppKit

extension NSAttributedString.Key {
    /// UDF border specification bitmask (Int)
    static let udfBorderSpec = NSAttributedString.Key("com.udfeditor.borderSpec")
    /// UDF cell fill color (Int32 ARGB)
    static let udfFillColor = NSAttributedString.Key("com.udfeditor.fillColor")
    /// UDF table name (String)
    static let udfTableName = NSAttributedString.Key("com.udfeditor.tableName")
    /// UDF row type (String)
    static let udfRowType = NSAttributedString.Key("com.udfeditor.rowType")
    /// UDF list ID (Int)
    static let udfListId = NSAttributedString.Key("com.udfeditor.listId")
    /// UDF number type (String)
    static let udfNumberType = NSAttributedString.Key("com.udfeditor.numberType")
    /// UDF bullet type (String)
    static let udfBulletType = NSAttributedString.Key("com.udfeditor.bulletType")
    /// UDF list type - "numbered" or "bulleted" (String)
    static let udfListType = NSAttributedString.Key("com.udfeditor.listType")
    /// UDF list level (Int)
    static let udfListLevel = NSAttributedString.Key("com.udfeditor.listLevel")
    /// UDF border style name (String)
    static let udfBorderName = NSAttributedString.Key("com.udfeditor.borderName")
    /// UDF border style type (String)
    static let udfBorderStyle = NSAttributedString.Key("com.udfeditor.borderStyle")
    /// UDF border width (Double)
    static let udfBorderWidth = NSAttributedString.Key("com.udfeditor.borderWidth")
    /// UDF border color (Int32 ARGB)
    static let udfBorderColor = NSAttributedString.Key("com.udfeditor.borderColor")
    /// UDF cell vertical alignment (String)
    static let udfVerticalAlign = NSAttributedString.Key("com.udfeditor.verticalAlign")
    /// Marks a paragraph that represents an explicit UDF page break (Bool)
    static let udfPageBreak = NSAttributedString.Key("com.udfeditor.pageBreak")
    /// Original UDF font family name (String). Preserved verbatim so fonts not
    /// installed on macOS (e.g. "Calibri Light") survive a load→save round-trip
    /// instead of collapsing to the system font's family.
    static let udfFontFamily = NSAttributedString.Key("com.udfeditor.fontFamily")
    /// Original base64 image bytes (String). Reused on save so loaded images are
    /// not re-encoded JPEG→PNG (size bloat / quality loss).
    static let udfImageData = NSAttributedString.Key("com.udfeditor.imageData")

    // Table metadata not representable in NSTextTable, stashed on cell
    // paragraphs so an opened table round-trips exactly through editor save.
    static let udfTableAlign = NSAttributedString.Key("com.udfeditor.table.align")
    static let udfTableWidth = NSAttributedString.Key("com.udfeditor.table.width")
    static let udfTableCellpadding = NSAttributedString.Key("com.udfeditor.table.cellpadding")
    static let udfTableCellspacing = NSAttributedString.Key("com.udfeditor.table.cellspacing")
    static let udfColumnSpans = NSAttributedString.Key("com.udfeditor.table.columnSpans")
    static let udfTableBorderName = NSAttributedString.Key("com.udfeditor.table.borderName")
    static let udfTableBorderStyle = NSAttributedString.Key("com.udfeditor.table.borderStyle")
    static let udfTableBorderWidth = NSAttributedString.Key("com.udfeditor.table.borderWidth")
    static let udfTableBorderColor = NSAttributedString.Key("com.udfeditor.table.borderColor")
    static let udfTableBorderSpec = NSAttributedString.Key("com.udfeditor.table.borderSpec")
    static let udfRowName = NSAttributedString.Key("com.udfeditor.rowName")
    /// Per-cell relative width (Double).
    static let udfCellWidth = NSAttributedString.Key("com.udfeditor.cellWidth")
    /// Row minimum height (Double).
    static let udfRowHeightMin = NSAttributedString.Key("com.udfeditor.rowHeightMin")
    /// Row actual height (Double).
    static let udfRowHeight = NSAttributedString.Key("com.udfeditor.rowHeight")
}
