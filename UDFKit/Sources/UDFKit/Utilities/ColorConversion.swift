import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Convert a signed ARGB Int32 to RGBA components (0.0–1.0).
public func argbToComponents(_ value: Int32) -> (r: Double, g: Double, b: Double, a: Double) {
    let unsigned = UInt32(bitPattern: value)
    let a = Double((unsigned >> 24) & 0xFF) / 255.0
    let r = Double((unsigned >> 16) & 0xFF) / 255.0
    let g = Double((unsigned >> 8) & 0xFF) / 255.0
    let b = Double(unsigned & 0xFF) / 255.0
    return (r, g, b, a)
}

/// Convert RGBA components (0.0–1.0) to a signed ARGB Int32.
public func componentsToArgb(r: Double, g: Double, b: Double, a: Double = 1.0) -> Int32 {
    let unsigned: UInt32 =
        (UInt32(a * 255) << 24) |
        (UInt32(r * 255) << 16) |
        (UInt32(g * 255) << 8) |
        UInt32(b * 255)
    return Int32(bitPattern: unsigned)
}

#if canImport(AppKit)
public extension NSColor {
    /// Create NSColor from a signed ARGB Int32.
    convenience init(argbInt32 value: Int32) {
        let c = argbToComponents(value)
        self.init(srgbRed: CGFloat(c.r), green: CGFloat(c.g), blue: CGFloat(c.b), alpha: CGFloat(c.a))
    }

    /// Convert NSColor to a signed ARGB Int32.
    var argbInt32: Int32 {
        guard let c = usingColorSpace(.sRGB) else {
            return -16777216 // fallback to black
        }
        return componentsToArgb(
            r: Double(c.redComponent),
            g: Double(c.greenComponent),
            b: Double(c.blueComponent),
            a: Double(c.alphaComponent)
        )
    }
}
#endif
