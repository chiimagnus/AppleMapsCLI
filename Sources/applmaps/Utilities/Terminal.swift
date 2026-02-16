import Darwin

enum Terminal {
    static var isStdoutTTY: Bool {
        isatty(fileno(stdout)) == 1
    }
}
