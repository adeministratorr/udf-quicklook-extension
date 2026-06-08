import Foundation

public enum UDFSection: Sendable {
    case header
    case body
    case footer
}

public struct OffsetEntry {
    public let element: InlineElement
    public let startOffset: Int
    public let length: Int
    public let blockId: Int
    public let section: UDFSection
}

public struct CDataResult {
    public let cdata: String
    public let entries: [OffsetEntry]
}

/// Build the CDATA text and offset entries from a document's sections.
/// Header blocks come first, then body, then footer — offsets cover the
/// whole range, matching the `<content startOffset=...>` layout expected
/// by UDF readers.
public func buildCData(
    header: [BlockElement],
    body: [BlockElement],
    footer: [BlockElement]
) -> CDataResult {
    var textParts: [String] = []
    var entries: [OffsetEntry] = []
    var offset = 0
    var blockId = 0
    var currentSection: UDFSection = .body

    func processParagraph(_ para: Paragraph) {
        let currentBlockId = blockId
        blockId += 1

        if para.runs.isEmpty {
            // Empty paragraph: insert zero-width space and point a real-offset
            // length-1 content entry at it (the official editor records each
            // empty line at its own offset with its own font, not 0/1).
            let style = para.emptyContentStyle
                ?? TextStyle(fontFamily: "Times New Roman", fontSize: 10)
            entries.append(OffsetEntry(
                element: .text(TextRun(text: "", style: style)),
                startOffset: offset,
                length: 1,
                blockId: currentBlockId,
                section: currentSection
            ))
            textParts.append("\u{200B}")
            offset += 1
        } else {
            for run in para.runs {
                switch run {
                case .text(let textRun):
                    let len = runeCount(textRun.text)
                    entries.append(OffsetEntry(
                        element: run,
                        startOffset: offset,
                        length: len,
                        blockId: currentBlockId,
                        section: currentSection
                    ))
                    textParts.append(textRun.text)
                    offset += len

                case .image(_):
                    entries.append(OffsetEntry(
                        element: run,
                        startOffset: offset,
                        length: 1,
                        blockId: currentBlockId,
                        section: currentSection
                    ))
                    textParts.append("\u{FFFC}")
                    offset += 1

                case .tab(let tabRun):
                    entries.append(OffsetEntry(
                        element: .tab(tabRun),
                        startOffset: offset,
                        length: 1,
                        blockId: currentBlockId,
                        section: currentSection
                    ))
                    textParts.append("\t")
                    offset += 1
                }
            }
        }

        // Paragraph separator
        textParts.append("\n")
        offset += 1
    }

    func processTable(_ table: Table) {
        for row in table.rows {
            for cell in row.cells {
                processBlocks(cell.content)
            }
        }
    }

    func processBlocks(_ blocks: [BlockElement]) {
        for block in blocks {
            switch block {
            case .paragraph(let para):
                processParagraph(para)
            case .table(let table):
                processTable(table)
            case .pageBreak:
                // Mirrors the inner empty paragraph the serializer emits:
                // zero-width space + paragraph separator. The official editor
                // writes a real-offset length-1 content (Times New Roman/10).
                let id = blockId
                blockId += 1
                entries.append(OffsetEntry(
                    element: .text(TextRun(text: "", style: TextStyle(fontFamily: "Times New Roman", fontSize: 10))),
                    startOffset: offset,
                    length: 1,
                    blockId: id,
                    section: currentSection
                ))
                textParts.append("\u{200B}\n")
                offset += 2
            }
        }
    }

    if !header.isEmpty {
        currentSection = .header
        processBlocks(header)
    }
    currentSection = .body
    processBlocks(body)
    if !footer.isEmpty {
        currentSection = .footer
        processBlocks(footer)
    }

    return CDataResult(
        cdata: textParts.joined(),
        entries: entries
    )
}
