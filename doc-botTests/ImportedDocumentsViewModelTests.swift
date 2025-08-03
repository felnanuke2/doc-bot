//
//  ImportedDocumentsViewModelTests.swift
//  doc-botTests
//
//  Created by Unit Tests on 03/08/25.
//

import Testing
@testable import doc_bot
import Factory
import Foundation
import Combine

@MainActor
struct ImportedDocumentsViewModelTests {
    
    // MARK: - Mock Dependencies
    
    actor MockChunkGeneratorRepository: ChunkGeneratorRepository {
        func generateChunks(documentID: UUID, from text: String) async -> [EmbeddableChunk] {
            // Return mock chunks based on text length
            guard !text.isEmpty else { return [] }
            
            let chunkSize = max(1, text.count / 100) // Create chunks based on text length
            var chunks: [EmbeddableChunk] = []
            
            for i in 0..<min(chunkSize, 5) { // Limit to 5 chunks for testing
                let content = "Chunk \(i + 1): \(String(text.prefix(50)))"
                chunks.append(EmbeddableChunk(content: content, documentID: documentID))
            }
            
            return chunks
        }
    }
    
    actor MockChunkEmbeddingRepository: ChunkEmbeddingRepository {
        func embed(chunk: EmbeddableChunk) async -> EmbeddedChunk {
            let embedded = EmbeddedChunk(id: chunk.id, content: chunk.content, documentID: chunk.documentID)
            embedded.embedding = Array(repeating: 0.5, count: 512)
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
        private let shouldSucceed: Bool
        private let mockContent: String
        
        init(shouldSucceed: Bool = true, mockContent: String = "This is mock PDF content with multiple sentences for testing chunking and embedding functionality.") {
            self.shouldSucceed = shouldSucceed
            self.mockContent = mockContent
        }
        
        func extractContent(from fileURL: URL) async -> String? {
            return shouldSucceed ? mockContent : nil
        }
    }
    
    class MockCompletionRepository: CompletionRepository {
        func generateCompletion(context: any ContextualPrompt, cancellationToken: CancellationToken?) -> AsyncThrowingStream<CompletionResult, Error> {
            AsyncThrowingStream { continuation in
                continuation.yield(.progressing("Mock response"))
                continuation.yield(.finished("Mock response completed"))
                continuation.finish()
            }
        }
        
        func generateCompletion(for prompt: String, cancellationToken: CancellationToken?) -> AsyncThrowingStream<CompletionResult, Error> {
            AsyncThrowingStream { continuation in
                continuation.yield(.progressing("Mock response"))
                continuation.yield(.finished("Mock response completed"))
                continuation.finish()
            }
        }
    }
    
    class MockModelDownloaderRepository: ModelDownloaderRepository {
        func downloadModel(from url: URL) -> AsyncStream<ModelDownloadResult> {
            AsyncStream { continuation in
                continuation.yield(.progressing(0.5))
                continuation.yield(.finished(url))
                continuation.finish()
            }
        }
        
        func localModelURL(for url: URL) -> URL? {
            return URL(fileURLWithPath: "/mock/path/to/model")
        }
    }
    
    class MockImportedDocumentRepository: ImportedDocumentRepository {
        private var documents: [ImportedDocument] = []
        private var nextId = 1
        
        func create(entity: ImportedDocument) async throws -> ImportedDocument {
            let newDocument = ImportedDocument(
                id: entity.id ?? UUID(),
                name: entity.name,
                conversations: entity.conversations ?? [],
                createdAt: entity.createdAt ?? Date(),
                updatedAt: entity.updatedAt ?? Date()
            )
            documents.append(newDocument)
            return newDocument
        }
        
        func read(id: UUID) async throws -> ImportedDocument? {
            return documents.first { $0.id == id }
        }
        
        func update(entity: ImportedDocument) async throws -> ImportedDocument {
            guard let index = documents.firstIndex(where: { $0.id == entity.id }) else {
                throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
            }
            documents[index] = entity
            return entity
        }
        
        func delete(id: UUID) async throws {
            documents.removeAll { $0.id == id }
        }
        
        func list() async throws -> [ImportedDocument] {
            return documents
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupMockDependencies() {
        Container.shared.chunkGeneratorRepository.register { MockChunkGeneratorRepository() }
        Container.shared.chunkEmbeddingRepository.register { MockChunkEmbeddingRepository() }
        Container.shared.vectorChunkRepository.register { MockVectorChunkRepository() }
        Container.shared.documentContentExtractor.register { MockDocumentContentExtractor() }
        Container.shared.completionRepository.register { MockCompletionRepository() }
        Container.shared.modelDownloaderRepository.register { MockModelDownloaderRepository() }
        Container.shared.importedDocumentRepository.register { MockImportedDocumentRepository() }
    }
    
    private func createTestViewModel() -> ImportedDocumentsViewModel {
        setupMockDependencies()
        let viewModel = ImportedDocumentsViewModel()
        return viewModel
    }
    
    // MARK: - ViewModel Initialization Tests
    
    @Test("ImportedDocumentsViewModel initializes with correct default state")
    func testViewModelInitializesWithCorrectDefaultState() async throws {
        let viewModel = createTestViewModel()
        
        // Allow some time for initialization to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(viewModel.isImporting == false, "Should not be importing initially")
        #expect(viewModel.importError == nil, "Should have no import error initially")
        #expect(viewModel.importProgress == 0.0, "Import progress should be 0.0 initially")
        #expect(viewModel.loadingContent == false, "Should not be loading content after initialization")
    }
    
    @Test("ImportedDocumentsViewModel loads documents on initialization")
    func testViewModelLoadsDocumentsOnInitialization() async throws {
        // Pre-populate repository with test documents
        setupMockDependencies()
        let mockRepo = Container.shared.importedDocumentRepository() as! MockImportedDocumentRepository
        let testDoc = ImportedDocument(
            id: UUID(),
            name: "Test Document.pdf",
            conversations: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        _ = try await mockRepo.create(entity: testDoc)
        
        let viewModel = ImportedDocumentsViewModel()
        
        // Allow time for async initialization
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        #expect(viewModel.documents.count == 1, "Should load documents from repository")
        #expect(viewModel.documents.first?.name == "Test Document.pdf", "Should load correct document")
    }
    
    // MARK: - Document Import Tests
    
    @Test("ImportedDocumentsViewModel successfully imports document")
    func testViewModelSuccessfullyImportsDocument() async throws {
        let viewModel = createTestViewModel()
        let testURL = URL(fileURLWithPath: "/test/document.pdf")
        
        // Track state changes
        var stateChanges: [(isImporting: Bool, progress: Double)] = []
        let cancellable = viewModel.$isImporting.combineLatest(viewModel.$importProgress)
            .sink { isImporting, progress in
                stateChanges.append((isImporting, progress))
            }
        
        // Import document
        await viewModel.importDocument(from: testURL)
        
        // Verify final state
        #expect(viewModel.isImporting == false, "Should not be importing after completion")
        #expect(viewModel.importError == nil, "Should have no error after successful import")
        #expect(viewModel.documents.count == 1, "Should have added document to collection")
        #expect(viewModel.documents.first?.name == "document.pdf", "Should have correct document name")
        
        cancellable.cancel()
    }
    
    @Test("ImportedDocumentsViewModel handles import with empty content")
    func testViewModelHandlesImportWithEmptyContent() async throws {
        // Setup mock extractor that returns empty content
        Container.shared.chunkGeneratorRepository.register { MockChunkGeneratorRepository() }
        Container.shared.chunkEmbeddingRepository.register { MockChunkEmbeddingRepository() }
        Container.shared.vectorChunkRepository.register { MockVectorChunkRepository() }
        Container.shared.documentContentExtractor.register { MockDocumentContentExtractor(mockContent: "") }
        Container.shared.completionRepository.register { MockCompletionRepository() }
        Container.shared.modelDownloaderRepository.register { MockModelDownloaderRepository() }
        Container.shared.importedDocumentRepository.register { MockImportedDocumentRepository() }
        
        let viewModel = ImportedDocumentsViewModel()
        let testURL = URL(fileURLWithPath: "/test/empty-document.pdf")
        
        await viewModel.importDocument(from: testURL)
        
        #expect(viewModel.isImporting == false, "Should complete import even with empty content")
        #expect(viewModel.documents.count == 1, "Should still create document entry")
        #expect(viewModel.documents.first?.name == "empty-document.pdf", "Should have correct document name")
    }
    
    @Test("ImportedDocumentsViewModel handles failed content extraction")
    func testViewModelHandlesFailedContentExtraction() async throws {
        // Setup mock extractor that fails
        Container.shared.chunkGeneratorRepository.register { MockChunkGeneratorRepository() }
        Container.shared.chunkEmbeddingRepository.register { MockChunkEmbeddingRepository() }
        Container.shared.vectorChunkRepository.register { MockVectorChunkRepository() }
        Container.shared.documentContentExtractor.register { MockDocumentContentExtractor(shouldSucceed: false) }
        Container.shared.completionRepository.register { MockCompletionRepository() }
        Container.shared.modelDownloaderRepository.register { MockModelDownloaderRepository() }
        Container.shared.importedDocumentRepository.register { MockImportedDocumentRepository() }
        
        let viewModel = ImportedDocumentsViewModel()
        let testURL = URL(fileURLWithPath: "/test/failed-document.pdf")
        
        await viewModel.importDocument(from: testURL)
        
        #expect(viewModel.isImporting == false, "Should complete import even with failed extraction")
        #expect(viewModel.documents.count == 1, "Should still create document entry")
    }
    
    // MARK: - State Management Tests
    
    @Test("ImportedDocumentsViewModel manages import progress correctly")
    func testViewModelManagesImportProgressCorrectly() async throws {
        let viewModel = createTestViewModel()
        let testURL = URL(fileURLWithPath: "/test/progress-document.pdf")
        
        // Track progress changes
        var progressValues: [Double] = []
        let cancellable = viewModel.$importProgress.sink { progress in
            progressValues.append(progress)
        }
        
        await viewModel.importDocument(from: testURL)
        
        #expect(progressValues.first == 0.0, "Should start with 0.0 progress")
        #expect(progressValues.count > 1, "Should update progress during import")
        
        cancellable.cancel()
    }
    
    @Test("ImportedDocumentsViewModel resets state between imports")
    func testViewModelResetsStateBetweenImports() async throws {
        let viewModel = createTestViewModel()
        let testURL1 = URL(fileURLWithPath: "/test/document1.pdf")
        let testURL2 = URL(fileURLWithPath: "/test/document2.pdf")
        
        // First import
        await viewModel.importDocument(from: testURL1)
        #expect(viewModel.documents.count == 1, "Should have one document after first import")
        
        // Second import
        await viewModel.importDocument(from: testURL2)
        #expect(viewModel.documents.count == 2, "Should have two documents after second import")
        #expect(viewModel.isImporting == false, "Should not be importing after second completion")
        #expect(viewModel.importProgress == 0.0, "Progress should be reset")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("ImportedDocumentsViewModel handles repository errors gracefully")
    func testViewModelHandlesRepositoryErrorsGracefully() async throws {
        // Create a repository that throws errors
        class FailingMockRepository: ImportedDocumentRepository {
            func create(entity: ImportedDocument) async throws -> ImportedDocument {
                throw NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock repository error"])
            }
            
            func read(id: UUID) async throws -> ImportedDocument? { nil }
            func update(entity: ImportedDocument) async throws -> ImportedDocument { throw NSError(domain: "TestError", code: 500) }
            func delete(id: UUID) async throws { throw NSError(domain: "TestError", code: 500) }
            func list() async throws -> [ImportedDocument] { [] }
        }
        
        Container.shared.chunkGeneratorRepository.register { MockChunkGeneratorRepository() }
        Container.shared.chunkEmbeddingRepository.register { MockChunkEmbeddingRepository() }
        Container.shared.vectorChunkRepository.register { MockVectorChunkRepository() }
        Container.shared.documentContentExtractor.register { MockDocumentContentExtractor() }
        Container.shared.completionRepository.register { MockCompletionRepository() }
        Container.shared.modelDownloaderRepository.register { MockModelDownloaderRepository() }
        Container.shared.importedDocumentRepository.register { FailingMockRepository() }
        
        let viewModel = ImportedDocumentsViewModel()
        let testURL = URL(fileURLWithPath: "/test/error-document.pdf")
        
        // This should not crash the app
        await viewModel.importDocument(from: testURL)
        
        #expect(viewModel.isImporting == false, "Should complete even with repository error")
    }
}
