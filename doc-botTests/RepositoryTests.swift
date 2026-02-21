//
//  RepositoryTests.swift
//  doc-botTests
//
//  Created by Unit Tests on 03/08/25.
//

import Testing
@testable import doc_bot
import Foundation

@MainActor
struct RepositoryTests {
    
    // MARK: - Mock Repository Implementations for Testing
    
    actor MockChunkEmbeddingRepository: ChunkEmbeddingRepository {
        private var embeddingCounter = 0
        private let mockEmbedding = Array(repeating: 0.5, count: 512)
        
        func embed(chunk: EmbeddableChunk) async -> EmbeddedChunk {
            let embedded = EmbeddedChunk(id: chunk.id, documentChunk: chunk.documentChunk, documentID: chunk.documentID)
            embedded.embedding = mockEmbedding
            return embedded
        }
        
        func embed(chunks: [EmbeddableChunk]) async -> [EmbeddedChunk] {
            var results: [EmbeddedChunk] = []
            for chunk in chunks {
                let embedded = await embed(chunk: chunk)
                results.append(embedded)
            }
            return results
        }
        
        func searchRelevantChunk(for query: String, chunks: [EmbeddedChunk], limit: Int) async -> [EmbeddedChunk] {
            return Array(chunks.prefix(limit))
        }
    }
    
    class MockVectorChunkRepository: VectorChunkRepository {
        private var storage: [UUID: [EmbeddedChunk]] = [:]
        
        func store(embedded: [EmbeddedChunk], for documentID: UUID) async {
            storage[documentID] = embedded
        }
        
        func restoreEmbeddings(for documentID: UUID) async -> [EmbeddedChunk]? {
            return storage[documentID]
        }
    }
    
    class MockDocumentContentExtractor: DocumentContentExtractor {
        private let mockContent: String
        
        init(mockContent: String = "This is mock content from a PDF document. It contains multiple sentences to test chunking functionality.") {
            self.mockContent = mockContent
        }
        
        func extractContent(from fileURL: URL) async -> [DocumentPageContent]? {
            return [DocumentPageContent(pageNumber: 0, text: mockContent)]
        }
    }
    
    // MARK: - NaturalLanguageChunkGenerator Tests
    
    @Test("NaturalLanguageChunkGenerator creates chunks from text")
    func testNaturalLanguageChunkGeneratorCreatesChunks() async throws {
        let generator = NaturalLanguageChunkGenerator()
        let documentID = UUID()
        let testText = """
        This is the first sentence. This is the second sentence with more content to test the chunking mechanism. 
        Here we have a third sentence that should be included in the chunk generation process. 
        Finally, this is the fourth sentence to ensure we have enough content for multiple chunks.
        """
        
        let pages = [DocumentPageContent(pageNumber: 0, text: testText)]
        let chunks = await generator.generateChunks(documentID: documentID, from: pages)
        
        #expect(chunks.count > 0, "Should generate at least one chunk")
        #expect(chunks.allSatisfy { $0.documentID == documentID }, "All chunks should have correct document ID")
        #expect(chunks.allSatisfy { !$0.content.isEmpty }, "All chunks should have content")
    }
    
    @Test("NaturalLanguageChunkGenerator handles empty text")
    func testNaturalLanguageChunkGeneratorHandlesEmptyText() async throws {
        let generator = NaturalLanguageChunkGenerator()
        let documentID = UUID()
        let emptyText = ""
        
        let pages = [DocumentPageContent(pageNumber: 0, text: emptyText)]
        let chunks = await generator.generateChunks(documentID: documentID, from: pages)
        
        #expect(chunks.isEmpty, "Empty text should produce no chunks")
    }
    
    @Test("NaturalLanguageChunkGenerator handles whitespace-only text")
    func testNaturalLanguageChunkGeneratorHandlesWhitespaceText() async throws {
        let generator = NaturalLanguageChunkGenerator()
        let documentID = UUID()
        let whitespaceText = "   \n\t   \n   "
        
        let pages = [DocumentPageContent(pageNumber: 0, text: whitespaceText)]
        let chunks = await generator.generateChunks(documentID: documentID, from: pages)
        
        #expect(chunks.isEmpty, "Whitespace-only text should produce no chunks")
    }
    
    // MARK: - ChunkEmbeddingRepository Tests
    
    @Test("MockChunkEmbeddingRepository embeds single chunk")
    func testMockChunkEmbeddingRepositoryEmbedsSingleChunk() async throws {
        let repository = MockChunkEmbeddingRepository()
        let documentID = UUID()
        let chunk = EmbeddableChunk(content: "Test content", documentID: documentID)
        
        let embedded = await repository.embed(chunk: chunk)
        
        #expect(embedded.id == chunk.id)
        #expect(embedded.content == chunk.content)
        #expect(embedded.documentID == documentID)
        #expect(embedded.embedding != nil, "Embedding should not be nil")
        #expect(embedded.embedding?.count == 512, "Embedding should have 512 dimensions")
    }
    
    @Test("MockChunkEmbeddingRepository embeds multiple chunks")
    func testMockChunkEmbeddingRepositoryEmbedsMultipleChunks() async throws {
        let repository = MockChunkEmbeddingRepository()
        let documentID = UUID()
        let chunks = [
            EmbeddableChunk(content: "First chunk", documentID: documentID),
            EmbeddableChunk(content: "Second chunk", documentID: documentID),
            EmbeddableChunk(content: "Third chunk", documentID: documentID)
        ]
        
        let embedded = await repository.embed(chunks: chunks)
        
        #expect(embedded.count == 3)
        #expect(embedded.allSatisfy { $0.embedding != nil }, "All embeddings should be generated")
        #expect(embedded.allSatisfy { $0.documentID == documentID }, "All should have correct document ID")
    }
    
    @Test("MockChunkEmbeddingRepository searches relevant chunks")
    func testMockChunkEmbeddingRepositorySearchesRelevantChunks() async throws {
        let repository = MockChunkEmbeddingRepository()
        let documentID = UUID()
        let embeddedChunks = [
            EmbeddedChunk(id: UUID(), documentChunk: DocumentChunk(text: "First chunk", pageNumber: 0), documentID: documentID),
            EmbeddedChunk(id: UUID(), documentChunk: DocumentChunk(text: "Second chunk", pageNumber: 0), documentID: documentID),
            EmbeddedChunk(id: UUID(), documentChunk: DocumentChunk(text: "Third chunk", pageNumber: 0), documentID: documentID),
            EmbeddedChunk(id: UUID(), documentChunk: DocumentChunk(text: "Fourth chunk", pageNumber: 0), documentID: documentID)
        ]
        
        let relevantChunks = await repository.searchRelevantChunk(
            for: "test query", 
            chunks: embeddedChunks, 
            limit: 2
        )
        
        #expect(relevantChunks.count == 2, "Should return exactly 2 chunks as requested")
    }
    
    // MARK: - VectorChunkRepository Tests
    
    @Test("MockVectorChunkRepository stores and retrieves embeddings")
    func testMockVectorChunkRepositoryStoresAndRetrievesEmbeddings() async throws {
        let repository = MockVectorChunkRepository()
        let documentID = UUID()
        let embeddedChunks = [
            EmbeddedChunk(id: UUID(), documentChunk: DocumentChunk(text: "First chunk", pageNumber: 0), documentID: documentID),
            EmbeddedChunk(id: UUID(), documentChunk: DocumentChunk(text: "Second chunk", pageNumber: 0), documentID: documentID)
        ]
        
        // Store embeddings
        await repository.store(embedded: embeddedChunks, for: documentID)
        
        // Retrieve embeddings
        let retrieved = await repository.restoreEmbeddings(for: documentID)
        
        #expect(retrieved != nil, "Should retrieve stored embeddings")
        #expect(retrieved?.count == 2, "Should retrieve all stored embeddings")
        #expect(retrieved?[0].content == "First chunk", "Content should match")
        #expect(retrieved?[1].content == "Second chunk", "Content should match")
    }
    
    @Test("MockVectorChunkRepository returns nil for non-existent document")
    func testMockVectorChunkRepositoryReturnsNilForNonExistentDocument() async throws {
        let repository = MockVectorChunkRepository()
        let nonExistentDocumentID = UUID()
        
        let retrieved = await repository.restoreEmbeddings(for: nonExistentDocumentID)
        
        #expect(retrieved == nil, "Should return nil for non-existent document")
    }
    
    // MARK: - DocumentContentExtractor Tests
    
    @Test("MockDocumentContentExtractor returns mock content")
    func testMockDocumentContentExtractorReturnsMockContent() async throws {
        let mockContent = "Custom mock content for testing"
        let extractor = MockDocumentContentExtractor(mockContent: mockContent)
        let testURL = URL(fileURLWithPath: "/test/path/document.pdf")
        
        let extractedContent = await extractor.extractContent(from: testURL)
        
        #expect(extractedContent?.first?.text == mockContent, "Should return the mock content")
    }
    
    @Test("MockDocumentContentExtractor handles multiple calls")
    func testMockDocumentContentExtractorHandlesMultipleCalls() async throws {
        let extractor = MockDocumentContentExtractor()
        let testURL1 = URL(fileURLWithPath: "/test/path/document1.pdf")
        let testURL2 = URL(fileURLWithPath: "/test/path/document2.pdf")
        
        let content1 = await extractor.extractContent(from: testURL1)
        let content2 = await extractor.extractContent(from: testURL2)
        
        #expect(content1 != nil, "Should return content for first call")
        #expect(content2 != nil, "Should return content for second call")
        #expect(content1?.first?.text == content2?.first?.text, "Should return same mock content for all calls")
    }
    
    // MARK: - Integration Tests
    
    @Test("Full document processing pipeline")
    func testFullDocumentProcessingPipeline() async throws {
        // Setup
        let generator = NaturalLanguageChunkGenerator()
        let embedder = MockChunkEmbeddingRepository()
        let vectorStore = MockVectorChunkRepository()
        let contentExtractor = MockDocumentContentExtractor()
        
        let documentID = UUID()
        let testURL = URL(fileURLWithPath: "/test/document.pdf")
        
        // Execute pipeline
        let content = await contentExtractor.extractContent(from: testURL)
        #expect(content != nil, "Content extraction should succeed")
        
        let chunks = await generator.generateChunks(documentID: documentID, from: content ?? [])
        #expect(chunks.count > 0, "Should generate chunks")
        
        let embedded = await embedder.embed(chunks: chunks)
        #expect(embedded.count == chunks.count, "Should embed all chunks")
        
        await vectorStore.store(embedded: embedded, for: documentID)
        let retrieved = await vectorStore.restoreEmbeddings(for: documentID)
        #expect(retrieved?.count == embedded.count, "Should store and retrieve all embeddings")
    }
}
