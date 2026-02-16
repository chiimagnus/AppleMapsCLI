import ArgumentParser

@main
struct ApplMaps: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Agent-first Apple Maps CLI for macOS"
    )

    mutating func run() async throws {
        // Root command is a container for subcommands.
    }
}
