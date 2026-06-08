import Foundation

/// Count Unicode codepoints (runes), not UTF-16 code units or grapheme clusters.
/// This matches JavaScript's `Array.from(text).length`.
public func runeCount(_ s: String) -> Int {
    return s.unicodeScalars.count
}

/// Convert a string to an array of rune strings (one Unicode scalar per element).
/// This matches JavaScript's `Array.from(text)`.
public func toRunes(_ s: String) -> [String] {
    return s.unicodeScalars.map { String($0) }
}

/// Extract a substring by rune offset and length.
/// Returns the substring spanning `length` Unicode scalars starting at `startOffset`.
public func runeSubstring(_ s: String, startOffset: Int, length: Int) -> String {
    let scalars = s.unicodeScalars
    let startIndex = scalars.index(scalars.startIndex, offsetBy: startOffset)
    let endIndex = scalars.index(startIndex, offsetBy: length)
    return String(scalars[startIndex..<endIndex])
}
