import Foundation

/// Bir tablo hücresi kenarının hangi kenarlarının çizileceği.
public struct BorderEdges: Equatable, Sendable {
    public var top: Bool
    public var right: Bool
    public var bottom: Bool
    public var left: Bool
    public init(top: Bool, right: Bool, bottom: Bool, left: Bool) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }
    public static let none = BorderEdges(top: false, right: false, bottom: false, left: false)
}

/// Hücre kenarı görünürlük kuralı (UYAP / udf-converter-go `IsBorderVisible` referansı).
/// Bir kenar SADECE şu durumda çizilir (hepsi birden):
///   1. borderName != "borderNone"
///   2. borderWidth > 0
///   3. renk near-white değil  (near-white = R,G,B hepsi > 240/255 olan renk)
///   4. (borderSpec & kenarBiti) != 0  — top=1, right=2, bottom=4, left=8
public func visibleBorderEdges(borderName: String, borderWidth: Double,
                               borderSpec: Int, borderColor: Int32) -> BorderEdges {
    if borderName == "borderNone" { return .none }
    if borderWidth <= 0 { return .none }
    let c = argbToComponents(borderColor)
    let t = 240.0 / 255.0
    // Alpha yok sayılır; UYAP kenar renkleri her zaman tam opaktır.
    if c.r > t && c.g > t && c.b > t { return .none }
    return BorderEdges(
        top:    borderSpec & 1 != 0,
        right:  borderSpec & 2 != 0,
        bottom: borderSpec & 4 != 0,
        left:   borderSpec & 8 != 0
    )
}
