import Foundation
import NaturalLanguage

final class NaturalLanguageReferenceResolver: ReferenceOutput {
    private let embeddingModel: NLEmbedding
    private let minimumScore = 0.45
    private let minimumTokenOverlap = 2
    private let maxReferences = 1
    private let fallbackMinimumScore = 0.35

    init() {
        guard let model = NLEmbedding.wordEmbedding(for: .english) else {
            fatalError("Unable to load embedding model")
        }
        self.embeddingModel = model
    }

    func resolveReferences(generatedAnswer: String, candidateChunks: [DocumentChunk]) -> [DocumentChunk] {
        let answerTokens = tokenSet(for: generatedAnswer)
        let sentenceEmbeddings = sentenceEmbeddings(for: generatedAnswer)
        let embeddingsToUse = sentenceEmbeddings.isEmpty ? [embedding(for: generatedAnswer)] : sentenceEmbeddings
        guard embeddingsToUse.contains(where: { !$0.isEmpty }) else { return [] }

        let scored = candidateChunks.compactMap { chunk -> ScoredChunk? in
            let chunkEmbedding = embedding(for: chunk.text)
            guard !chunkEmbedding.isEmpty else { return nil }
            let score = embeddingsToUse
                .map { cosineSimilarity($0, chunkEmbedding) }
                .max() ?? 0
            let overlap = tokenOverlapCount(answerTokens, tokenSet(for: chunk.text))
            return ScoredChunk(chunk: chunk, score: score, overlap: overlap)
        }

        let filtered = scored
            .filter { $0.score >= minimumScore && $0.overlap >= minimumTokenOverlap }
            .sorted { $0.score > $1.score }
        let selected = selectDistinctPages(from: filtered, maxCount: maxReferences)
        if !selected.isEmpty {
            return selected
        }

        let fallback = scored
            .filter { $0.score >= fallbackMinimumScore && $0.overlap >= 1 }
            .sorted { $0.score > $1.score }
        return selectDistinctPages(from: fallback, maxCount: 1)
    }

    private struct ScoredChunk {
        let chunk: DocumentChunk
        let score: Double
        let overlap: Int
    }

    private func selectDistinctPages(from scored: [ScoredChunk], maxCount: Int) -> [DocumentChunk] {
        var seenPages = Set<Int>()
        var results: [DocumentChunk] = []
        for item in scored {
            guard results.count < maxCount else { break }
            if !seenPages.contains(item.chunk.pageNumber) {
                seenPages.insert(item.chunk.pageNumber)
                results.append(item.chunk)
            }
        }
        return results
    }

    private func sentenceEmbeddings(for text: String) -> [[Double]] {
        let tokenizer = NLTokenizer(unit: .sentence)
        tokenizer.string = text
        let ranges = tokenizer.tokens(for: text.startIndex..<text.endIndex)
        return ranges.compactMap { range in
            let sentence = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
            let embedding = embedding(for: String(sentence))
            return embedding.isEmpty ? nil : embedding
        }
    }

    private func embedding(for text: String) -> [Double] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let embeddings = words.compactMap { embeddingModel.vector(for: $0) }
        return average(embeddings)
    }

    private func tokenSet(for text: String) -> Set<String> {
        let tokens = text
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count >= 3 }
        return Set(tokens)
    }

    private func tokenOverlapCount(_ lhs: Set<String>, _ rhs: Set<String>) -> Int {
        lhs.intersection(rhs).count
    }

    private func average(_ vectors: [[Double]]) -> [Double] {
        guard !vectors.isEmpty else { return [] }
        let sum = vectors.reduce(into: Array(repeating: 0.0, count: vectors[0].count)) { result, vector in
            for (index, value) in vector.enumerated() {
                result[index] += value
            }
        }
        return sum.map { $0 / Double(vectors.count) }
    }

    private func cosineSimilarity(_ v1: [Double], _ v2: [Double]) -> Double {
        guard v1.count == v2.count, !v1.isEmpty else { return 0 }
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let magnitude1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        guard magnitude1 > 0, magnitude2 > 0 else { return 0 }
        return dotProduct / (magnitude1 * magnitude2)
    }
}
