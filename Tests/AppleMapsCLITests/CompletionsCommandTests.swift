import Foundation
import Testing
@testable import AppleMapsCLI

@Suite("Completions Command Parsing Tests")
struct CompletionsCommandParsingTests {
    @Test("Parses zsh shell argument")
    func parseZsh() throws {
        let parsed = try CompletionsCommand.parse(["zsh"])
        #expect(parsed.shell == "zsh")
    }

    @Test("Parses bash shell argument")
    func parseBash() throws {
        let parsed = try CompletionsCommand.parse(["bash"])
        #expect(parsed.shell == "bash")
    }

    @Test("Parses fish shell argument")
    func parseFish() throws {
        let parsed = try CompletionsCommand.parse(["fish"])
        #expect(parsed.shell == "fish")
    }

    @Test("Parses schema flag without shell argument")
    func parseSchemaFlag() throws {
        let parsed = try CompletionsCommand.parse(["--json-schema"])
        #expect(parsed.shell == nil)
        #expect(parsed.jsonSchema)
    }

    @Test("Rejects unsupported shell names at runtime validation")
    func rejectsUnsupportedShell() {
        #expect(throws: CLIError.user("Shell must be one of: zsh, bash, fish.")) {
            _ = try CompletionsCommand.parseShell(rawValue: "powershell")
        }
    }
}

@Suite("Completions Script Generation Tests")
struct CompletionsScriptGenerationTests {
    @Test("Generates non-empty scripts for each supported shell", arguments: [
        CompletionsCommand.Shell.zsh,
        CompletionsCommand.Shell.bash,
        CompletionsCommand.Shell.fish
    ])
    func generateScript(shell: CompletionsCommand.Shell) throws {
        let executablePath = FileManager.default.currentDirectoryPath + "/.build/debug/applemaps"
        let script = try CompletionsCommand.generateScript(shell: shell, executablePath: executablePath)

        #expect(!script.isEmpty)

        switch shell {
        case .zsh:
            #expect(script.contains("#compdef applemaps"))
        case .bash:
            #expect(script.contains("complete -o filenames -F _applemaps applemaps"))
        case .fish:
            #expect(script.contains("complete -c 'applemaps'"))
        }
    }
}
