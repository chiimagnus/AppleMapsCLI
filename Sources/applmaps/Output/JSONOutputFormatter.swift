import Foundation

enum JSONOutputFormatterError: Error, Sendable, Equatable {
    case invalidUTF8
    case invalidFields(String)
}

enum JSONOutputFormatter {
    static func format<T: Encodable>(
        _ payload: T,
        forcePretty: Bool,
        stdoutIsTTY: Bool = Terminal.isStdoutTTY
    ) throws -> String {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        if forcePretty || stdoutIsTTY {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }

        let data = try encoder.encode(payload)
        guard let output = String(data: data, encoding: .utf8) else {
            throw JSONOutputFormatterError.invalidUTF8
        }

        return output
    }
}
