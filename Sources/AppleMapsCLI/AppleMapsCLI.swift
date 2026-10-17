import ArgumentParser

@main
struct AppleMapsCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "applemaps",
        abstract: "Agent-first Apple Maps CLI for macOS",
        subcommands: [
            GeocodeCommand.self,
            ReverseCommand.self,
            SearchCommand.self,
            CompleteCommand.self,
            DirectionsCommand.self,
            ETACommand.self,
            OpenCommand.self,
            PinCommand.self,
            CategoriesCommand.self,
            CompletionsCommand.self
        ]
    )
}
