import Testing
@testable import applmaps

@Suite("Smoke Tests")
struct SmokeTests {
    @Test("Builds test target")
    func compiles() {
        #expect(true)
    }
}
