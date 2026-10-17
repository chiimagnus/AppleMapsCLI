import Foundation

enum CommandSchemaOutput {
    static func render(
        command: String,
        pretty: Bool,
        fields: String?
    ) throws -> String {
        guard let schema = CommandSchemaRegistry.schema(for: command) else {
            throw CLIError.user("No schema is available for command '\(command)'.")
        }

        return try JSONOutputFormatter.format(
            schema,
            forcePretty: pretty,
            fields: fields,
            keyEncodingStrategy: .useDefaultKeys
        )
    }
}
