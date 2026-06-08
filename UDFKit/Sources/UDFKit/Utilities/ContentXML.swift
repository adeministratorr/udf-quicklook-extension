import Foundation
import ZIPFoundation

/// Extract the raw `content.xml` text from UDF file data (a ZIP archive).
/// Useful for tests and tooling that need to inspect the serialized XML.
public func udfContentXML(from data: Data) throws -> String {
    let archive = try Archive(data: data, accessMode: .read)
    guard let entry = archive["content.xml"] else {
        throw UDFParserError.missingContentXml
    }
    var bytes = Data()
    _ = try archive.extract(entry) { bytes.append($0) }
    guard let xml = String(data: bytes, encoding: .utf8) else {
        throw UDFParserError.invalidXml("content.xml is not valid UTF-8")
    }
    return xml
}
