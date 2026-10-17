import Foundation

struct StderrOutput: Sendable {
    func writeLine(_ text: String) {
        guard let data = "\(text)\n".data(using: .utf8) else {
            return
        }

        FileHandle.standardError.write(data)
    }
}
