import Foundation

enum TableGrid {
    /// A virtual column count divisible by each row's cell count, so per-row
    /// cells map to whole spans. Capped to keep NSTextTable manageable.
    static func units(forRowCellCounts counts: [Int]) -> Int {
        var l = 1
        for c in counts where c > 0 { l = lcm(l, c) }
        let scaled = l * 12
        return min(max(scaled, 12), 600)
    }
    private static func gcd(_ a: Int, _ b: Int) -> Int { b == 0 ? a : gcd(b, a % b) }
    private static func lcm(_ a: Int, _ b: Int) -> Int { a / gcd(a, b) * b }
}
