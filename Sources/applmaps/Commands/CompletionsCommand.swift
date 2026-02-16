import ArgumentParser
import Foundation

struct CompletionsCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "completions",
        abstract: "Generate shell completion scripts (zsh, bash, fish)."
    )

    @Argument(help: "Shell type: zsh, bash, fish")
    var shell: Shell

    mutating func run() throws {
        do {
            let script = try Self.generateScript(shell: shell)
            if script.hasSuffix("\n") {
                print(script, terminator: "")
            } else {
                print(script)
            }
        } catch let error as CLIError {
            StderrOutput().writeLine(error.message)
            throw ExitCode(rawValue: error.exitCode)
        } catch {
            StderrOutput().writeLine("Unexpected completions command failure: \(error.localizedDescription)")
            throw ExitCode(rawValue: 2)
        }
    }

    static func generateScript(
        shell: Shell,
        executablePath: String = Bundle.main.executablePath ?? CommandLine.arguments[0]
    ) throws -> String {
        guard !executablePath.isEmpty else {
            throw CLIError.network("Unable to resolve executable path for completion generation.")
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["--generate-completion-script", shell.rawValue]

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw CLIError.network("Failed to launch completion generator: \(error.localizedDescription)")
        }

        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        guard process.terminationStatus == 0 else {
            let stderrText = String(data: stderrData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw CLIError.network(stderrText?.nilIfEmpty ?? "Failed to generate completion script.")
        }

        guard let script = String(data: stdoutData, encoding: .utf8), !script.isEmpty else {
            throw CLIError.network("Completion generator returned empty output.")
        }

        return script
    }
}

extension CompletionsCommand {
    enum Shell: String, ExpressibleByArgument, CaseIterable, Sendable {
        case zsh
        case bash
        case fish
    }
}

private extension String {
    var nilIfEmpty: String? {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
    }
}
