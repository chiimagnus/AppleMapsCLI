import ArgumentParser

@main
struct ApplMaps: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "applmaps",
        abstract: "Agent-first Apple Maps CLI for macOS",
        subcommands: [
            GeocodeCommand.self,
            ReverseCommand.self,
            SearchCommand.self,
            DirectionsCommand.self,
            ETACommand.self,
            OpenCommand.self,
            PinCommand.self
        ]
    )
}
