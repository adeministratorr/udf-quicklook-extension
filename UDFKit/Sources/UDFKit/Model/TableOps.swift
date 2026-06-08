import Foundation

public extension Table {
    /// A fresh empty cell carrying the table's default border + a unit width.
    private func emptyCell() -> TableCell {
        TableCell(border: border, width: 100, content: [.paragraph(Paragraph())])
    }

    mutating func insertRow(at index: Int) {
        let i = max(0, min(index, rows.count))
        let cellCount = max(columns, 1)
        let cells = (0..<cellCount).map { _ in emptyCell() }
        rows.insert(TableRow(cells: cells), at: i)
    }

    mutating func deleteRow(at index: Int) {
        guard rows.count > 1, rows.indices.contains(index) else { return }
        rows.remove(at: index)
    }

    mutating func insertColumn(at index: Int) {
        let i = max(0, min(index, columns))
        columns += 1
        var widths = columnWidths
        while widths.count < columns - 1 { widths.append(100) }
        widths.insert(100, at: min(i, widths.count))
        columnWidths = widths
        for r in rows.indices {
            let at = min(i, rows[r].cells.count)
            rows[r].cells.insert(emptyCell(), at: at)
        }
    }

    /// Deletes the cell at `index` in every row by ordinal. NOTE: in rows that
    /// contain a horizontal merge (fewer cells than `columns`), cell ordinals no
    /// longer line up across rows, so the deleted cell may not be the visually
    /// expected column. Best-effort for v1's single-merge cases; bounds-guarded.
    mutating func deleteColumn(at index: Int) {
        guard columns > 1 else { return }
        columns -= 1
        if columnWidths.indices.contains(index) { columnWidths.remove(at: index) }
        for r in rows.indices where rows[r].cells.indices.contains(index) {
            if rows[r].cells.count > 1 { rows[r].cells.remove(at: index) }
        }
    }

    /// Merge cells `from...through` (inclusive) in `row` into the first cell.
    mutating func mergeCellsHorizontally(row: Int, from: Int, through: Int) {
        guard rows.indices.contains(row) else { return }
        let lo = max(0, min(from, through))
        let hi = min(rows[row].cells.count - 1, max(from, through))
        guard hi > lo else { return }
        var first = rows[row].cells[lo]
        var width = first.width ?? 100
        for k in (lo + 1)...hi {
            width += rows[row].cells[k].width ?? 100
            for block in rows[row].cells[k].content {
                if case .paragraph(let p) = block, p.runs.isEmpty { continue }
                first.content.append(block)
            }
        }
        first.width = width
        rows[row].cells.replaceSubrange(lo...hi, with: [first])
    }

    /// Split a (previously merged) cell back into unit-width cells so the row
    /// returns to `columns` cells.
    mutating func unmergeCell(row: Int, at index: Int) {
        guard rows.indices.contains(row), rows[row].cells.indices.contains(index) else { return }
        let missing = columns - rows[row].cells.count
        guard missing > 0 else { return }
        rows[row].cells[index].width = 100
        let extras = (0..<missing).map { _ in emptyCell() }
        rows[row].cells.insert(contentsOf: extras, at: index + 1)
    }

    mutating func setRowHeight(row: Int, minHeight: Double) {
        guard rows.indices.contains(row) else { return }
        rows[row].heightMin = minHeight
        rows[row].height = max(rows[row].height, minHeight)
    }
}
