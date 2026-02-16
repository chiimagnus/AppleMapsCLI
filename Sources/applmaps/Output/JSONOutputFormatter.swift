import Foundation

enum JSONOutputFormatterError: Error, Sendable, Equatable {
    case invalidUTF8
    case invalidFields(String)
}

enum JSONOutputFormatter {
    static func format<T: Encodable>(
        _ payload: T,
        forcePretty: Bool,
        fields: String? = nil,
        stdoutIsTTY: Bool = Terminal.isStdoutTTY
    ) throws -> String {
        let prettyPrinted = forcePretty || stdoutIsTTY
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        if prettyPrinted {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }

        var data = try encoder.encode(payload)
        if let fields {
            let fieldSet = try parseFields(fields)
            data = try projectEncodedPayload(data, fields: fieldSet, prettyPrinted: prettyPrinted)
        }

        guard let output = String(data: data, encoding: .utf8) else {
            throw JSONOutputFormatterError.invalidUTF8
        }

        return output
    }

    private static func parseFields(_ rawFields: String) throws -> Set<String> {
        let fields = rawFields
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard !fields.isEmpty, fields.allSatisfy({ !$0.isEmpty }) else {
            throw JSONOutputFormatterError.invalidFields(
                "Fields must be a comma-separated list of non-empty names."
            )
        }

        return Set(fields)
    }

    private static func projectEncodedPayload(
        _ data: Data,
        fields: Set<String>,
        prettyPrinted: Bool
    ) throws -> Data {
        let object = try JSONSerialization.jsonObject(with: data)
        let projectedObject = projectValue(object, fields: fields) ?? emptyProjectionRoot(for: object)

        var options: JSONSerialization.WritingOptions = []
        if prettyPrinted {
            options.insert(.prettyPrinted)
            options.insert(.sortedKeys)
        }

        return try JSONSerialization.data(withJSONObject: projectedObject, options: options)
    }

    private static func emptyProjectionRoot(for object: Any) -> Any {
        if object is [Any] {
            return [Any]()
        }
        return [String: Any]()
    }

    private static func projectValue(_ value: Any, fields: Set<String>) -> Any? {
        if let dictionary = value as? [String: Any] {
            var projectedDictionary: [String: Any] = [:]

            for (key, childValue) in dictionary {
                if fields.contains(key) {
                    projectedDictionary[key] = childValue
                    continue
                }

                if let projectedChild = projectValue(childValue, fields: fields),
                   !isEmptyProjection(projectedChild) {
                    projectedDictionary[key] = projectedChild
                }
            }

            return projectedDictionary.isEmpty ? nil : projectedDictionary
        }

        if let array = value as? [Any] {
            let projectedArray = array.compactMap { element in
                projectValue(element, fields: fields)
            }
            return projectedArray.isEmpty ? nil : projectedArray
        }

        return nil
    }

    private static func isEmptyProjection(_ value: Any) -> Bool {
        if let dictionary = value as? [String: Any] {
            return dictionary.isEmpty
        }
        if let array = value as? [Any] {
            return array.isEmpty
        }
        return false
    }
}
