//
//  CompletionRepository.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 21/07/25.
//

import Foundation

enum CompletionResult {
    case failure(Error)
    case waiting
    case progressing(String)
    case finished(String)
}

/// A repository for generating text completions.
protocol CompletionRepository {
    /// Generates a completion for a given prompt asynchronously.
    /// - Parameter prompt: The input prompt string.
    /// - Returns: The result string.
    func generateCompletion(for prompt: String) -> AsyncStream<CompletionResult>
}
