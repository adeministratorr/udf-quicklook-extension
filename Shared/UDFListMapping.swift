import AppKit
import UDFKit

/// Bidirectional mapping between UDF list types (numberType/bulletType strings)
/// and NSTextList.MarkerFormat, so the editor renders list markers natively
/// while preserving UDF fidelity on save.
enum UDFListMapping {

    static let defaultBulletType = "BULLET_TYPE_ELLIPSE"
    static let defaultNumberType = "NUMBER_TYPE_NUMBER_DOT"

    /// Build an NSTextList whose marker matches the UDF list spec.
    static func makeTextList(_ list: ListProperties) -> NSTextList {
        let format: String
        switch list.type {
        case .numbered:
            format = numberFormat(list.numberType ?? defaultNumberType)
        case .bulleted:
            format = bulletFormat(list.bulletType ?? defaultBulletType)
        }
        return NSTextList(markerFormat: NSTextList.MarkerFormat(format), options: 0)
    }

    /// Reverse-map an NSTextList back to UDF ListProperties, used when the user
    /// creates a list via the toolbar (no custom UDF attribute keys present).
    static func listProperties(from textList: NSTextList, level: Int) -> ListProperties {
        let raw = textList.markerFormat.rawValue
        if raw.contains("{decimal}") || raw.contains("{roman}") || raw.contains("{alpha}") {
            return ListProperties(
                type: .numbered,
                numberType: numberType(for: raw),
                level: level
            )
        }
        return ListProperties(
            type: .bulleted,
            bulletType: bulletType(for: raw),
            level: level
        )
    }

    // MARK: - Bullet mapping
    //
    // Bullet markers are rendered as literal glyphs (the renderer injects the
    // marker as text), since several UYAP bullets — arrow, triangle, second
    // diamond — have no NSTextList built-in format. Glyphs chosen to match the
    // official editor's appearance. The exact UDF type string is preserved
    // verbatim on save via the `udfBulletType` attribute, so these mappings only
    // drive rendering and the toolbar reverse-mapping for newly created lists.

    private static func bulletFormat(_ udfType: String) -> String {
        switch udfType {
        case "BULLET_TYPE_ELLIPSE":      return "\u{2022}"   // •
        case "BULLET_TYPE_RECTANGLE":    return "\u{25A0}"   // ■
        case "BULLET_TYPE_RECTANGLE_D":  return "\u{25A1}"   // □
        case "BULLET_TYPE_DIAMOND":      return "\u{25C6}"   // ◆
        case "BULLET_TYPE_DIAMOND_2":    return "\u{25C7}"   // ◇
        case "BULLET_TYPE_ARROW":        return "\u{27A2}"   // ➢
        case "BULLET_TYPE_TRIANGLE":     return "\u{25BA}"   // ►
        default:                         return "\u{2022}"   // •
        }
    }

    private static func bulletType(for markerFormat: String) -> String {
        if markerFormat.contains("\u{25A0}") { return "BULLET_TYPE_RECTANGLE" }
        if markerFormat.contains("\u{25A1}") { return "BULLET_TYPE_RECTANGLE_D" }
        if markerFormat.contains("\u{25C6}") { return "BULLET_TYPE_DIAMOND" }
        if markerFormat.contains("\u{25C7}") { return "BULLET_TYPE_DIAMOND_2" }
        if markerFormat.contains("\u{27A2}") { return "BULLET_TYPE_ARROW" }
        if markerFormat.contains("\u{25BA}") { return "BULLET_TYPE_TRIANGLE" }
        return "BULLET_TYPE_ELLIPSE"
    }

    // MARK: - Number mapping
    //
    // Real UYAP number types (from genuine documents):
    //   NUMBER_TYPE_NUMBER_DOT[_2/_3]        → 1.
    //   NUMBER_TYPE_NUMBER_PARANTHESE[_2]    → 1)
    //   NUMBER_TYPE_NUMBER_TRE               → 1
    //   NUMBER_TYPE_ROMAN_BIG_DOT            → I.
    //   NUMBER_TYPE_ROMAN_SMALL_DOT          → i.
    //   NUMBER_TYPE_CHAR_BIG_DOT[_2]         → A.
    //   NUMBER_TYPE_CHAR_SMALL_DOT           → a.
    //   NUMBER_TYPE_CHAR_SMALL_PARANTHESE    → a)

    private static func numberFormat(_ udfType: String) -> String {
        switch udfType {
        case "NUMBER_TYPE_NUMBER_DOT",
             "NUMBER_TYPE_NUMBER_DOT_2",
             "NUMBER_TYPE_NUMBER_DOT_3":         return "{decimal}."
        case "NUMBER_TYPE_NUMBER_PARANTHESE",
             "NUMBER_TYPE_NUMBER_PARANTHESE_2":  return "{decimal})"
        case "NUMBER_TYPE_NUMBER_TRE":           return "{decimal}"
        case "NUMBER_TYPE_ROMAN_BIG_DOT":        return "{upper-roman}."
        case "NUMBER_TYPE_ROMAN_SMALL_DOT":      return "{lower-roman}."
        case "NUMBER_TYPE_CHAR_BIG_DOT",
             "NUMBER_TYPE_CHAR_BIG_2":           return "{upper-alpha}."
        case "NUMBER_TYPE_CHAR_SMALL_DOT":       return "{lower-alpha}."
        case "NUMBER_TYPE_CHAR_SMALL_PARANTHESE": return "{lower-alpha})"
        default:                                 return "{decimal}."
        }
    }

    private static func numberType(for markerFormat: String) -> String {
        if markerFormat.contains("{upper-roman}") { return "NUMBER_TYPE_ROMAN_BIG_DOT" }
        if markerFormat.contains("{lower-roman}") { return "NUMBER_TYPE_ROMAN_SMALL_DOT" }
        if markerFormat.contains("{upper-alpha}") { return "NUMBER_TYPE_CHAR_BIG_DOT" }
        if markerFormat.contains("{lower-alpha}") {
            return markerFormat.hasSuffix(")") ? "NUMBER_TYPE_CHAR_SMALL_PARANTHESE" : "NUMBER_TYPE_CHAR_SMALL_DOT"
        }
        if markerFormat.hasSuffix(")") { return "NUMBER_TYPE_NUMBER_PARANTHESE" }
        if markerFormat.hasSuffix(".") { return "NUMBER_TYPE_NUMBER_DOT" }
        return "NUMBER_TYPE_NUMBER_TRE"
    }
}
