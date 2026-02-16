import Testing
@testable import applmaps

@Suite("Command Schema Registry Tests")
struct CommandSchemaRegistryTests {
    @Test("Provides schema for each implemented command", arguments: [
        "geocode",
        "reverse",
        "search",
        "complete",
        "directions",
        "eta",
        "open",
        "pin",
        "categories",
        "completions"
    ])
    func schemaExists(command: String) {
        let schema = CommandSchemaRegistry.schema(for: command)
        #expect(schema != nil)
        #expect(schema?.command == command)
        #expect(schema?.input.type == "object")
    }

    @Test("Unknown command schema lookup returns nil")
    func unknownSchema() {
        #expect(CommandSchemaRegistry.schema(for: "unknown") == nil)
    }

    @Test("Geocode schema exports oneOf output for single and batch modes")
    func geocodeOneOf() {
        let schema = CommandSchemaRegistry.schema(for: "geocode")

        #expect(schema?.output.oneOf?.count == 2)
        #expect(schema?.output.oneOf?.first?.properties?["query"] != nil)
        #expect(schema?.output.oneOf?.last?.properties?["count"] != nil)
    }

    @Test("Search schema output includes result place shape")
    func searchSchemaShape() {
        let schema = CommandSchemaRegistry.schema(for: "search")
        let resultsItems = schema?.output.properties?["results"]?.items

        #expect(resultsItems?.properties?["name"]?.type == "string")
        #expect(resultsItems?.properties?["coordinate"]?.properties?["lat"]?.type == "number")
        #expect(resultsItems?.properties?["maps_url"]?.type == "string")
    }

    @Test("Complete schema output includes suggestion shape")
    func completeSchemaShape() {
        let schema = CommandSchemaRegistry.schema(for: "complete")
        let resultsItems = schema?.output.properties?["results"]?.items

        #expect(resultsItems?.properties?["title"]?.type == "string")
        #expect(resultsItems?.properties?["subtitle"]?.type == "string")
        #expect(resultsItems?.properties?["display"]?.type == "string")
    }

    @Test("Categories schema output includes id and mapkit value")
    func categoriesSchemaShape() {
        let schema = CommandSchemaRegistry.schema(for: "categories")
        let resultsItems = schema?.output.properties?["results"]?.items

        #expect(resultsItems?.properties?["id"]?.type == "string")
        #expect(resultsItems?.properties?["mapkit_value"]?.type == "string")
    }
}
