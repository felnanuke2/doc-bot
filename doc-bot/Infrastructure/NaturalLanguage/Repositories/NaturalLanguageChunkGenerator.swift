//
//  NaturalLanguageChunkGenerator.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 21/07/25.
//


import Foundation
import NaturalLanguage



/// A chunk generator that uses the Natural Language framework to create consistently sized chunks of text.
///
/// This implementation groups sentences together to form chunks that are close to a target word count.
/// This is more effective for embedding than splitting by paragraphs, which can result in chunks
/// that are too small or vary widely in size.
class NaturalLanguageChunkGenerator: ChunkGeneratorRepository {
    
    /// The target word count for each chunk.
    ///
    /// The 512 token limit for many embedding models roughly corresponds to 350-400 English words.
    /// We use 384 as a conservative target to ensure the resulting chunks are under the limit.
    private let chunkTargetWordCount = 200
    
    /// Generates chunks by grouping sentences to reach a target word count.
    func generateChunks(documentID: UUID, from pages: [DocumentPageContent]) async -> [EmbeddableChunk] {
        var chunks: [EmbeddableChunk] = []

        for page in pages {
            let text = page.text
            let sentenceTokenizer = NLTokenizer(unit: .sentence)
            sentenceTokenizer.string = text

            let sentenceRanges = sentenceTokenizer.tokens(for: text.startIndex..<text.endIndex)
            let sentences: [(text: String, range: Range<String.Index>)] = sentenceRanges.compactMap { range in
                let sentenceText = text[range].trimmingCharacters(in: .whitespacesAndNewlines)
                return sentenceText.isEmpty ? nil : (sentenceText, range)
            }

            guard !sentences.isEmpty else { continue }

            var currentChunkWordCount = 0
            var currentChunkStart: Range<String.Index>.Bound?
            var currentChunkEnd: Range<String.Index>.Bound?

            for sentence in sentences {
                let sentenceWordCount = sentence.text.split(separator: " ").count
                let willOverflow = currentChunkWordCount > 0
                    && (currentChunkWordCount + sentenceWordCount > chunkTargetWordCount)

                if willOverflow, let start = currentChunkStart, let end = currentChunkEnd {
                    let chunkRange = start..<end
                    let chunkText = text[chunkRange].trimmingCharacters(in: .whitespacesAndNewlines)
                    if !chunkText.isEmpty {
                        let nsRange = NSRange(chunkRange, in: text)
                        let documentChunk = DocumentChunk(
                            text: String(chunkText),
                            pageNumber: page.pageNumber,
                            boundingBox: DocumentTextRange.from(nsRange)
                        )
                        chunks.append(EmbeddableChunk(documentChunk: documentChunk, documentID: documentID))
                    }

                    currentChunkStart = sentence.range.lowerBound
                    currentChunkEnd = sentence.range.upperBound
                    currentChunkWordCount = sentenceWordCount
                } else {
                    if currentChunkStart == nil {
                        currentChunkStart = sentence.range.lowerBound
                    }
                    currentChunkEnd = sentence.range.upperBound
                    currentChunkWordCount += sentenceWordCount
                }
            }

            if let start = currentChunkStart, let end = currentChunkEnd {
                let chunkRange = start..<end
                let chunkText = text[chunkRange].trimmingCharacters(in: .whitespacesAndNewlines)
                if !chunkText.isEmpty {
                    let nsRange = NSRange(chunkRange, in: text)
                    let documentChunk = DocumentChunk(
                        text: String(chunkText),
                        pageNumber: page.pageNumber,
                        boundingBox: DocumentTextRange.from(nsRange)
                    )
                    chunks.append(EmbeddableChunk(documentChunk: documentChunk, documentID: documentID))
                }
            }
        }

        return chunks
    }
}
