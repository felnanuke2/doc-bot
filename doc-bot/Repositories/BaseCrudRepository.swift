import Foundation

/// Generic protocol for CRUD operations on any entity.
protocol BaseCrudRepository {
    associatedtype Entity
    func create(entity: Entity) async throws -> Entity
    func read(id: UUID) async throws -> Entity?
    func update(entity: Entity) async throws -> Entity
    func delete(id: UUID) async throws
    func list() async throws -> [Entity]
}

