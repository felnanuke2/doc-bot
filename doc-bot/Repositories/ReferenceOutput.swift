protocol ReferenceOutput {
    func resolveReferences(generatedAnswer: String, candidateChunks: [DocumentChunk]) -> [DocumentChunk]
}
