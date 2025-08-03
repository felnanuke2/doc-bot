import Foundation

/// Protocol for generating conversation subjects based on messages
protocol SubjectRepository {
    /// Generates a subject string based on a list of chat messages
    /// - Parameter messages: Array of ChatMessage objects to analyze
    /// - Returns: A string representing the subject or topic of the conversation
    func generateSubject(from messages: [ChatMessage]) async throws -> String
}
