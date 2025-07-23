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
    
    func generateCompletion(for prompt: String) -> AsyncStream<CompletionResult> {
        AsyncStream { continuation in
            Task {
                await complete(text: prompt, continuation: continuation)
            }
            continuation.finish()
        }
    }

    private func complete(text: String, continuation: AsyncStream<CompletionResult>.Continuation) async -> Void {
        do {
            let llamaContext: LlamaCompletionContext = try LlamaCompletionContext.create_context(path:  "d")
            DispatchQueue.main.async {
                continuation.yield(.waiting)
            }
            let accumulator = OutputAccumulator()

            await llamaContext.completion_init(text: text)
            while await !llamaContext.is_done {
                let result = await llamaContext.completion_loop()
                await accumulator.append("\(result)")
                DispatchQueue.main.async {
                    continuation.yield(.progressing(result))
                }
            }

            await llamaContext.clear()
            let output = await accumulator.get()
            DispatchQueue.main.async {
                continuation.yield(.finished(output))
            }
        } catch {
            print("Error in LlamaCompletionRepository.complete: \(error)")
            DispatchQueue.main.async {
                continuation.yield(.finished("Error: Failed to initialize completion context"))
            }
        }
    }
}
