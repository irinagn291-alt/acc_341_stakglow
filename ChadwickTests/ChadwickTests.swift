import XCTest
@testable import Chadwick

/// Placeholder. Replace with the cases required by SPEC.md section 17.
final class ChadwickTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: ChadwickApp.self), "ChadwickApp")
    }
}
