//
//  CompletionRepository.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 21/07/25.
//

import Foundation

final class CancellationToken {
    private(set) var isCancelled = false

    func cancel() {
        isCancelled = true
    }
}

protocol ContextualPrompt {
    var content: String { get }
}

enum CompletionResult {
    case failure(Error)
    case waiting
    case progressing(String)
    case finished(String)
}

/// A repository for generating text completions.
protocol CompletionRepository {
    /// Generates a completion for a given prompt asynchronously, supporting cancellation.
    /// - Parameter prompt: The input prompt string.
    /// - Returns: An async throwing stream of completion results.
    func generateCompletion(for prompt: String, cancellationToken: CancellationToken?)
        -> AsyncThrowingStream<CompletionResult, Error>

    func generateCompletion( context: any ContextualPrompt, cancellationToken: CancellationToken?) -> AsyncThrowingStream<CompletionResult, Error>
}

protocol PromptContextGenerator {
    func generateContext(for prompt: String, with context: String) -> any ContextualPrompt
}
