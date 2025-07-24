import Foundation

private actor OutputAccumulator {
    private var output = ""
    func append(_ text: String) {
        output += text
    }
    func get() -> String {
        output
    }
}

class LlamaCompletionRepository: CompletionRepository {
    
    
    
    
    func generateCompletion(context: any ContextualPrompt, cancellationToken: CancellationToken?) -> AsyncThrowingStream<CompletionResult, any Error> {
        generateCompletion(for: context.content, cancellationToken: cancellationToken)
    }
   
    
    func generateCompletion(for prompt: String, cancellationToken: CancellationToken? = nil ) -> AsyncThrowingStream<CompletionResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    try await complete(text: prompt, continuation: continuation, cancelationToken: cancellationToken)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private func complete(text: String, continuation: AsyncThrowingStream<CompletionResult, Error>.Continuation,  cancelationToken: CancellationToken? ) async throws {
        // Check for cancellation before starting
        try Task.checkCancellation()
        // Use only file name, assume download is handled elsewhere
        let fileName = "ggml-model-q8_0.gguf"
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let modelUrl = documentsURL.appendingPathComponent(fileName)
        guard fileManager.fileExists(atPath: modelUrl.path) else {
            continuation.yield(.finished("Error: Model file not found"))
            return
        }
        let llamaContext: LlamaCompletionContext = try LlamaCompletionContext.create_context(path: modelUrl.path)
        continuation.yield(.waiting)
        let accumulator = OutputAccumulator()

        await llamaContext.completion_init(text: text)
        while await !llamaContext.is_done && cancelationToken?.isCancelled != true {
            // Check for cancellation during processing
            try Task.checkCancellation()
            let result = await llamaContext.completion_loop()
            await accumulator.append("\(result)")
            continuation.yield(.progressing(result))
        }

        await llamaContext.clear()
        let output = await accumulator.get()
        continuation.yield(.finished(output))
    }
}
