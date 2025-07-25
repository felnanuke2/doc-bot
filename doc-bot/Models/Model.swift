import Foundation

struct Model: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    let name: String
    let url: String
    let filename: String

    static func == (lhs: Model, rhs: Model) -> Bool {
        // Compare by url, name, and filename, not by id
        return lhs.url == rhs.url && lhs.name == rhs.name && lhs.filename == rhs.filename
    }
}
