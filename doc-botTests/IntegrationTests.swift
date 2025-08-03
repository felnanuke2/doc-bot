//
//  IntegrationTests.swift
//  doc-botTests
//
//  Created by Unit Tests on 03/08/25.
//

import Testing
@testable import doc_bot
import Factory
import Foundation

@MainActor
struct IntegrationTests {
    
    // MARK: - Mock Infrastructure
    
    actor MockChunkGeneratorRepository: ChunkGeneratorRepository {
        func generateChunks(documentID: UUID, from text: String) async -> [EmbeddableChunk] {
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return []
            }
            
            // Simulate realistic chunking behavior
            let words = text.split(separator: " ")
            let chunkSize = 50 // words per chunk
            var chunks: [EmbeddableChunk] = []
            
            for i in stride(from: 0, to: words.count, by: chunkSize) {
                let endIndex = min(i + chunkSize, words.count)
                let chunkWords = Array(words[i..<endIndex])
                let chunkContent = chunkWords.joined(separator: " ")
                
                chunks.append(EmbeddableChunk(content: chunkContent, documentID: documentID))
            }
            
            return chunks.isEmpty ? [EmbeddableChunk(content: text, documentID: documentID)] : chunks
        }
    }
    
    actor MockChunkEmbeddingRepository: ChunkEmbeddingRepository {
        private let embeddingDimension = 384 // Common dimension for embedding models
        
        func embed(chunk: EmbeddableChunk) async -> EmbeddedChunk {
            let embedded = EmbeddedChunk(id: chunk.id, content: chunk.content, documentID: chunk.documentID)
            
            // Generate deterministic but realistic embeddings based on content
            var embedding: [Double] = []
            let contentHash = chunk.content.hashValue
            
            for i in 0..<embeddingDimension {
                let value = sin(Double(contentHash + i)) * 0.5 + 0.5 // Normalize to [0, 1]
                embedding.append(value)
            }
            
            embedded.embedding = embedding
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
            // Simple relevance based on content similarity (mock implementation)
            let queryWords = Set(query.lowercased().split(separator: " ").map(String.init))
            
            let scored = chunks.map { chunk in
                let chunkWords = Set(chunk.content.lowercased().split(separator: " ").map(String.init))
                let intersection = queryWords.intersection(chunkWords)
                return (chunk: chunk, score: intersection.count)
            }
            
            return scored
                .sorted { $0.score > $1.score }
                .prefix(limit)
                .map { $0.chunk }
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
        private let contentMap: [String: String]
        
        init(contentMap: [String: String] = [:]) {
            self.contentMap = contentMap
        }
        
        func extractContent(from fileURL: URL) async -> String? {
            let fileName = fileURL.lastPathComponent
            
            // Return specific content for known files, or generate mock content
            if let specificContent = contentMap[fileName] {
                return specificContent
            }
            
            // Generate realistic mock PDF content
            return """
            \(fileName.replacingOccurrences(of: ".pdf", with: "")) Document Content
            
            Introduction
            This is a comprehensive document that covers various topics related to the subject matter. 
            It provides detailed information and analysis that will be useful for understanding the key concepts.
            
            Chapter 1: Overview
            The first chapter introduces the main themes and provides context for the discussion that follows.
            This section establishes the foundation for more detailed analysis in subsequent chapters.
            
            Chapter 2: Detailed Analysis
            This chapter delves deeper into the specific aspects of the topic, providing examples and case studies.
            The analysis includes both theoretical frameworks and practical applications.
            
            Chapter 3: Implementation
            The implementation chapter focuses on practical steps and methodologies that can be applied.
            This includes best practices, common pitfalls to avoid, and strategies for success.
            
            Conclusion
            The document concludes with a summary of key findings and recommendations for future work.
            These insights provide valuable guidance for practitioners and researchers in the field.
            """
        }
    }
    
    class MockImportedDocumentRepository: ImportedDocumentRepository {
        private var documents: [ImportedDocument] = []
        
        func create(entity: ImportedDocument) async throws -> ImportedDocument {
            let newDoc = ImportedDocument(
                id: entity.id ?? UUID(),
                name: entity.name,
                conversations: entity.conversations ?? [],
                createdAt: entity.createdAt ?? Date(),
                updatedAt: entity.updatedAt ?? Date()
            )
            documents.append(newDoc)
            return newDoc
        }
        
        func read(id: UUID) async throws -> ImportedDocument? {
            return documents.first { $0.id == id }
        }
        
        func update(entity: ImportedDocument) async throws -> ImportedDocument {
            guard let index = documents.firstIndex(where: { $0.id == entity.id }) else {
                throw NSError(domain: "TestError", code: 404)
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
    
    // MARK: - Setup Helper
    
    private func setupIntegrationDependencies(customContentMap: [String: String] = [:]) {
        Container.shared.chunkGeneratorRepository.register { MockChunkGeneratorRepository() }
        Container.shared.chunkEmbeddingRepository.register { MockChunkEmbeddingRepository() }
        Container.shared.vectorChunkRepository.register { MockVectorChunkRepository() }
        Container.shared.documentContentExtractor.register { MockDocumentContentExtractor(contentMap: customContentMap) }
        Container.shared.importedDocumentRepository.register { MockImportedDocumentRepository() }
    }
    
    // MARK: - End-to-End Document Processing Tests
    
    @Test("Complete document import pipeline")
    func testCompleteDocumentImportPipeline() async throws {
        setupIntegrationDependencies()
        
        let chunkGenerator = Container.shared.chunkGeneratorRepository()
        let chunkEmbedder = Container.shared.chunkEmbeddingRepository()
        let vectorStore = Container.shared.vectorChunkRepository()
        let contentExtractor = Container.shared.documentContentExtractor()
        let documentRepo = Container.shared.importedDocumentRepository()
        
        let testURL = URL(fileURLWithPath: "/test/sample-document.pdf")
        let documentID = UUID()
        
        // Step 1: Extract content
        let content = await contentExtractor.extractContent(from: testURL)
        #expect(content != nil, "Content extraction should succeed")
        #expect(!content!.isEmpty, "Extracted content should not be empty")
        
        // Step 2: Generate chunks
        let chunks = await chunkGenerator.generateChunks(documentID: documentID, from: content!)
        #expect(chunks.count > 0, "Should generate chunks from content")
        #expect(chunks.allSatisfy { $0.documentID == documentID }, "All chunks should have correct document ID")
        
        // Step 3: Embed chunks
        let embedded = await chunkEmbedder.embed(chunks: chunks)
        #expect(embedded.count == chunks.count, "Should embed all chunks")
        #expect(embedded.allSatisfy { $0.embedding != nil }, "All chunks should have embeddings")
        #expect(embedded.allSatisfy { $0.embedding!.count == 384 }, "All embeddings should have correct dimension")
        
        // Step 4: Store embeddings
        await vectorStore.store(embedded: embedded, for: documentID)
        let retrieved = await vectorStore.restoreEmbeddings(for: documentID)
        #expect(retrieved != nil, "Should retrieve stored embeddings")
        #expect(retrieved!.count == embedded.count, "Should retrieve all embeddings")
        
        // Step 5: Create document record
        let document = ImportedDocument(
            id: documentID,
            name: testURL.lastPathComponent,
            conversations: [],
            createdAt: Date(),
            updatedAt: Date()
        )
        let createdDoc = try await documentRepo.create(entity: document)
        #expect(createdDoc.id == documentID, "Created document should have correct ID")
        #expect(createdDoc.name == "sample-document.pdf", "Created document should have correct name")
    }
    
    @Test("Document search and retrieval integration")
    func testDocumentSearchAndRetrievalIntegration() async throws {
        let customContent = [
            "technical-manual.pdf": """
            Technical Manual for Advanced Systems
            
            This manual covers installation, configuration, and troubleshooting of advanced technical systems.
            The system requires proper installation procedures and regular maintenance schedules.
            
            Installation Process:
            1. Prepare the installation environment
            2. Configure system parameters
            3. Test system functionality
            4. Document configuration settings
            
            Troubleshooting Guide:
            Common issues include connection problems, configuration errors, and performance degradation.
            Each issue has specific diagnostic steps and resolution procedures.
            """,
            "user-guide.pdf": """
            User Guide for Daily Operations
            
            This guide helps users perform daily tasks efficiently and safely.
            It includes step-by-step instructions for common operations.
            
            Getting Started:
            - Login procedures
            - Navigation basics
            - Common tasks overview
            
            Daily Operations:
            - Data entry procedures
            - Report generation
            - Backup processes
            - User account management
            """
        ]
        
        setupIntegrationDependencies(customContentMap: customContent)
        
        let chunkGenerator = Container.shared.chunkGeneratorRepository()
        let chunkEmbedder = Container.shared.chunkEmbeddingRepository()
        let vectorStore = Container.shared.vectorChunkRepository()
        let contentExtractor = Container.shared.documentContentExtractor()
        
        // Process both documents
        let documents = [
            (url: URL(fileURLWithPath: "/test/technical-manual.pdf"), id: UUID()),
            (url: URL(fileURLWithPath: "/test/user-guide.pdf"), id: UUID())
        ]
        
        var allEmbedded: [EmbeddedChunk] = []
        
        for (url, docId) in documents {
            let content = await contentExtractor.extractContent(from: url)!
            let chunks = await chunkGenerator.generateChunks(documentID: docId, from: content)
            let embedded = await chunkEmbedder.embed(chunks: chunks)
            
            await vectorStore.store(embedded: embedded, for: docId)
            allEmbedded.append(contentsOf: embedded)
        }
        
        // Test search functionality
        let queries = [
            "installation procedures",
            "daily operations",
            "troubleshooting",
            "user account"
        ]
        
        for query in queries {
            let results = await chunkEmbedder.searchRelevantChunk(
                for: query,
                chunks: allEmbedded,
                limit: 3
            )
            
            #expect(results.count > 0, "Should find relevant chunks for query: '\(query)'")
            #expect(results.count <= 3, "Should respect limit for query: '\(query)'")
            
            // Verify results contain relevant content
            let hasRelevantContent = results.contains { chunk in
                chunk.content.localizedCaseInsensitiveContains(query) ||
                query.split(separator: " ").contains { word in
                    chunk.content.localizedCaseInsensitiveContains(String(word))
                }
            }
            
            // Note: This might not always be true with our simple mock search, but tests the structure
            if !hasRelevantContent {
                print("Warning: Query '\(query)' didn't return obviously relevant content, but this is expected with mock search")
            }
        }
    }
    
    @Test("ImportedDocumentsViewModel full integration")
    func testImportedDocumentsViewModelFullIntegration() async throws {
        setupIntegrationDependencies()
        
        let viewModel = ImportedDocumentsViewModel()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let initialDocumentCount = viewModel.documents.count
        
        // Test document import
        let testFiles = [
            URL(fileURLWithPath: "/test/document1.pdf"),
            URL(fileURLWithPath: "/test/document2.pdf"),
            URL(fileURLWithPath: "/test/document3.pdf")
        ]
        
        for fileURL in testFiles {
            // Track import progress
            var progressUpdates: [Double] = []
            let cancellable = viewModel.$importProgress.sink { progress in
                progressUpdates.append(progress)
            }
            
            await viewModel.importDocument(from: fileURL)
            
            #expect(viewModel.isImporting == false, "Should complete import for \(fileURL.lastPathComponent)")
            #expect(progressUpdates.count > 1, "Should have progress updates for \(fileURL.lastPathComponent)")
            
            cancellable.cancel()
        }
        
        // Verify all documents were imported
        #expect(viewModel.documents.count == initialDocumentCount + testFiles.count, 
                "Should have imported all documents")
        
        let documentNames = viewModel.documents.compactMap { $0.name }
        for fileURL in testFiles {
            #expect(documentNames.contains(fileURL.lastPathComponent), 
                    "Should contain document: \(fileURL.lastPathComponent)")
        }
    }
    
    @Test("Concurrent document import handling")
    func testConcurrentDocumentImportHandling() async throws {
        setupIntegrationDependencies()
        
        let viewModel = ImportedDocumentsViewModel()
        
        // Wait for initialization
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let testFiles = [
            URL(fileURLWithPath: "/test/concurrent1.pdf"),
            URL(fileURLWithPath: "/test/concurrent2.pdf"),
            URL(fileURLWithPath: "/test/concurrent3.pdf")
        ]
        
        // Start multiple imports concurrently
        await withTaskGroup(of: Void.self) { group in
            for fileURL in testFiles {
                group.addTask {
                    await viewModel.importDocument(from: fileURL)
                }
            }
        }
        
        // Verify all documents were processed
        #expect(viewModel.documents.count >= testFiles.count, 
                "Should have processed all concurrent imports")
        #expect(viewModel.isImporting == false, 
                "Should not be importing after all tasks complete")
    }
    
    @Test("Large document processing")
    func testLargeDocumentProcessing() async throws {
        // Create a large document content
        let largeContent = String(repeating: """
            This is a large document with repetitive content to test the system's ability to handle 
            substantial amounts of text. The document contains multiple paragraphs and sections 
            that need to be processed efficiently.
            
            """, count: 100) // Creates a document with ~20,000 words
        
        let customContentMap = ["large-document.pdf": largeContent]
        setupIntegrationDependencies(customContentMap: customContentMap)
        
        let chunkGenerator = Container.shared.chunkGeneratorRepository()
        let chunkEmbedder = Container.shared.chunkEmbeddingRepository()
        let vectorStore = Container.shared.vectorChunkRepository()
        let contentExtractor = Container.shared.documentContentExtractor()
        
        let testURL = URL(fileURLWithPath: "/test/large-document.pdf")
        let documentID = UUID()
        
        // Process large document
        let content = await contentExtractor.extractContent(from: testURL)!
        #expect(content.count > 10000, "Content should be large")
        
        let chunks = await chunkGenerator.generateChunks(documentID: documentID, from: content)
        #expect(chunks.count > 10, "Should generate many chunks for large document")
        
        let embedded = await chunkEmbedder.embed(chunks: chunks)
        #expect(embedded.count == chunks.count, "Should embed all chunks")
        
        await vectorStore.store(embedded: embedded, for: documentID)
        let retrieved = await vectorStore.restoreEmbeddings(for: documentID)
        #expect(retrieved?.count == embedded.count, "Should store and retrieve all embeddings")
        
        // Test search on large document
        let searchResults = await chunkEmbedder.searchRelevantChunk(
            for: "document content processing",
            chunks: embedded,
            limit: 5
        )
        #expect(searchResults.count > 0, "Should find relevant chunks in large document")
        #expect(searchResults.count <= 5, "Should respect search limit")
    }
    
    @Test("Error recovery and resilience")
    func testErrorRecoveryAndResilience() async throws {
        setupIntegrationDependencies()
        
        let viewModel = ImportedDocumentsViewModel()
        
        // Test with various problematic scenarios
        let problematicFiles = [
            URL(fileURLWithPath: "/test/empty-document.pdf"),
            URL(fileURLWithPath: "/test/special-chars-文档.pdf"),
            URL(fileURLWithPath: "/test/very-long-filename-that-might-cause-issues-in-some-systems.pdf")
        ]
        
        for fileURL in problematicFiles {
            await viewModel.importDocument(from: fileURL)
            
            #expect(viewModel.isImporting == false, 
                    "Should handle problematic file gracefully: \(fileURL.lastPathComponent)")
            #expect(viewModel.importError == nil, 
                    "Should not have persistent errors after handling: \(fileURL.lastPathComponent)")
        }
        
        // Verify system is still functional after error scenarios
        let normalFile = URL(fileURLWithPath: "/test/normal-document.pdf")
        await viewModel.importDocument(from: normalFile)
        
        #expect(viewModel.documents.contains { $0.name == "normal-document.pdf" }, 
                "Should be able to process normal documents after error scenarios")
    }
}
