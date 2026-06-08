import Foundation

/// Read a float attribute, returning fallback if missing or invalid.
func attrFloat(_ el: XMLElement, _ name: String, _ fallback: Double = 0) -> Double {
    guard let str = el.attribute(forName: name)?.stringValue, !str.isEmpty else {
        return fallback
    }
    return Double(str) ?? fallback
}

/// Read an integer attribute, returning fallback if missing or invalid.
func attrInt(_ el: XMLElement, _ name: String, _ fallback: Int = 0) -> Int {
    guard let str = el.attribute(forName: name)?.stringValue, !str.isEmpty else {
        return fallback
    }
    return Int(str) ?? fallback
}

/// Read an Int32 attribute, returning fallback if missing or invalid.
func attrInt32(_ el: XMLElement, _ name: String, _ fallback: Int32 = 0) -> Int32 {
    guard let str = el.attribute(forName: name)?.stringValue, !str.isEmpty else {
        return fallback
    }
    return Int32(str) ?? fallback
}

/// Read a string attribute, returning fallback if missing.
func attrStr(_ el: XMLElement, _ name: String, _ fallback: String = "") -> String {
    return el.attribute(forName: name)?.stringValue ?? fallback
}

/// Read a boolean attribute (true only if value is "true").
func attrBool(_ el: XMLElement, _ name: String) -> Bool {
    return el.attribute(forName: name)?.stringValue == "true"
}

/// True when the attribute is present (used to distinguish explicit from
/// inherited/default values for round-trip fidelity).
func attrPresent(_ el: XMLElement, _ name: String) -> Bool {
    return el.attribute(forName: name)?.stringValue != nil
}

/// Optional variants — nil when the attribute is absent.
func attrFloatOpt(_ el: XMLElement, _ name: String) -> Double? {
    guard let str = el.attribute(forName: name)?.stringValue, !str.isEmpty else { return nil }
    return Double(str)
}

func attrIntOpt(_ el: XMLElement, _ name: String) -> Int? {
    guard let str = el.attribute(forName: name)?.stringValue, !str.isEmpty else { return nil }
    return Int(str)
}

func attrInt32Opt(_ el: XMLElement, _ name: String) -> Int32? {
    guard let str = el.attribute(forName: name)?.stringValue, !str.isEmpty else { return nil }
    return Int32(str)
}

func attrStrOpt(_ el: XMLElement, _ name: String) -> String? {
    return el.attribute(forName: name)?.stringValue
}

/// Find child elements with a given tag name.
func childElements(_ parent: XMLElement, named tagName: String) -> [XMLElement] {
    return parent.elements(forName: tagName)
}

/// Find first child element with a given tag name.
func findElement(_ parent: XMLElement, named tagName: String) -> XMLElement? {
    return parent.elements(forName: tagName).first
}
