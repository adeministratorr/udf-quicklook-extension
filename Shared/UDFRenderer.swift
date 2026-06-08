// Shared/UDFRenderer.swift
import AppKit
import UDFKit

public enum UDFRenderError: Error {
    case unreadable(URL)
    case parseFailed(Error)
}

/// Parses a .udf file and renders header + body + footer into one attributed string.
/// Used identically by the preview extension, thumbnail extension, and host viewer.
public enum UDFRenderer {
    public static func attributedString(from url: URL) throws -> NSAttributedString {
        let data: Data
        do { data = try Data(contentsOf: url) }
        catch { throw UDFRenderError.unreadable(url) }

        let doc: UDFDocument
        do { doc = try UDFParser().parse(from: data) }
        catch { throw UDFRenderError.parseFailed(error) }

        let out = NSMutableAttributedString()
        if !doc.header.isEmpty {
            out.append(DocumentToAttributedString.convertBlocks(doc.header))
            out.append(NSAttributedString(string: "\n"))
        }
        out.append(DocumentToAttributedString.convert(doc))
        if !doc.footer.isEmpty {
            out.append(NSAttributedString(string: "\n"))
            out.append(DocumentToAttributedString.convertBlocks(doc.footer))
        }
        return out
    }
}
