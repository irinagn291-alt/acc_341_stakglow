import Foundation

/// A person on this phone. Points live on posted coupons, not on the tipster.
struct Tipster: Codable, Equatable, Sendable, Identifiable {
    var id: UUID
    var name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
