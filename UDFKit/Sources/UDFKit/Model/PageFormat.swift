import Foundation

public struct PageFormat: Sendable, Equatable, Codable {
    public var mediaSizeName: Int      // 1 = A4
    public var leftMargin: Double
    public var rightMargin: Double
    public var topMargin: Double
    public var bottomMargin: Double
    public var paperOrientation: Int   // 1 = portrait, 2 = landscape
    public var headerFOffset: Double
    public var footerFOffset: Double

    public init(
        mediaSizeName: Int = 1,
        leftMargin: Double = 42.52,
        rightMargin: Double = 28.35,
        topMargin: Double = 14.17,
        bottomMargin: Double = 14.17,
        paperOrientation: Int = 1,
        headerFOffset: Double = 20.0,
        footerFOffset: Double = 20.0
    ) {
        self.mediaSizeName = mediaSizeName
        self.leftMargin = leftMargin
        self.rightMargin = rightMargin
        self.topMargin = topMargin
        self.bottomMargin = bottomMargin
        self.paperOrientation = paperOrientation
        self.headerFOffset = headerFOffset
        self.footerFOffset = footerFOffset
    }

    public static let `default` = PageFormat()
}
