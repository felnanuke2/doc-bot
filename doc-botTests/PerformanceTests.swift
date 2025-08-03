//
//  PerformanceTests.swift
//  doc-botTests
//
//  Created by Unit Tests on 03/08/25.
//

import Testing
@testable import doc_bot
import Foundation

struct PerformanceTests {
    
    // MARK: - Array Chunking Performance
    
    @Test("Array chunking performance with large arrays")
    func testArrayChunkingPerformance() async throws {
        let largeArray = Array(1...10000)
        let chunkSize = 100
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let chunks = largeArray.chunked(into: chunkSize)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let timeElapsed = endTime - startTime
        
        #expect(chunks.count == 100, "Should create 100 chunks")
        #expect(timeElapsed < 1.0, "Chunking should complete within 1 second")
        
        // Verify chunking correctness
        let flattenedArray = chunks.flatMap { $0 }
        #expect(flattenedArray == largeArray, "Chunked array should maintain original order")
    }
    
    @Test("Array chunking performance with various chunk sizes")
    func testArrayChunkingPerformanceVariousChunkSizes() async throws {
        let testArray = Array(1...1000)
        let chunkSizes = [1, 10, 50, 100, 500, 1000]
        
        for chunkSize in chunkSizes {
            let startTime = CFAbsoluteTimeGetCurrent()
            let chunks = testArray.chunked(into: chunkSize)
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let timeElapsed = endTime - startTime
            let expectedChunkCount = (testArray.count + chunkSize - 1) / chunkSize
            
            #expect(chunks.count == expectedChunkCount, 
                    "Should create correct number of chunks for size \(chunkSize)")
            #expect(timeElapsed < 0.1, 
                    "Chunking should be fast for chunk size \(chunkSize)")
        }
    }
    
    // MARK: - Model Creation Performance
    
    @Test("ImportedDocument creation performance")
    func testImportedDocumentCreationPerformance() async throws {
        let documentCount = 1000
        var documents: [ImportedDocument] = []
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<documentCount {
            let document = ImportedDocument(
                id: UUID(),
                name: "Document_\(i).pdf",
                conversations: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            documents.append(document)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        #expect(documents.count == documentCount, "Should create all documents")
        #expect(timeElapsed < 1.0, "Document creation should be fast")
        
        // Test that all documents have unique IDs
        let uniqueIds = Set(documents.compactMap { $0.id })
        #expect(uniqueIds.count == documentCount, "All documents should have unique IDs")
    }
    
    @Test("EmbeddableChunk creation performance")
    func testEmbeddableChunkCreationPerformance() async throws {
        let chunkCount = 1000
        let documentID = UUID()
        var chunks: [EmbeddableChunk] = []
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<chunkCount {
            let chunk = EmbeddableChunk(
                content: "This is test content for chunk number \(i) with some additional text to make it more realistic.",
                documentID: documentID
            )
            chunks.append(chunk)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        #expect(chunks.count == chunkCount, "Should create all chunks")
        #expect(timeElapsed < 0.5, "Chunk creation should be fast")
        
        // Verify all chunks have unique IDs
        let uniqueIds = Set(chunks.map { $0.id })
        #expect(uniqueIds.count == chunkCount, "All chunks should have unique IDs")
        
        // Verify all chunks have the same document ID
        #expect(chunks.allSatisfy { $0.documentID == documentID }, 
                "All chunks should have the same document ID")
    }
    
    // MARK: - String Processing Performance
    
    @Test("Large text processing performance")
    func testLargeTextProcessingPerformance() async throws {
        // Create a large text (approximately 100KB)
        let baseText = "This is a sample sentence for performance testing. It contains multiple words and punctuation marks. "
        let largeText = String(repeating: baseText, count: 1000)
        
        #expect(largeText.count > 50000, "Text should be large enough for performance testing")
        
        // Test string operations that might be used in text processing
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Simulate text processing operations
        let words = largeText.split(separator: " ")
        let sentences = largeText.components(separatedBy: ". ")
        let lowercased = largeText.lowercased()
        let trimmed = largeText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        #expect(words.count > 1000, "Should extract many words")
        #expect(sentences.count > 100, "Should extract many sentences")
        #expect(lowercased.count == largeText.count, "Lowercased text should have same length")
        #expect(!trimmed.isEmpty, "Trimmed text should not be empty")
        #expect(timeElapsed < 1.0, "Text processing should complete within 1 second")
    }
    
    @Test("UUID generation performance")
    func testUUIDGenerationPerformance() async throws {
        let uuidCount = 10000
        var uuids: [UUID] = []
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<uuidCount {
            uuids.append(UUID())
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        #expect(uuids.count == uuidCount, "Should generate all UUIDs")
        #expect(timeElapsed < 1.0, "UUID generation should be fast")
        
        // Verify uniqueness
        let uniqueUUIDs = Set(uuids)
        #expect(uniqueUUIDs.count == uuidCount, "All UUIDs should be unique")
    }
    
    // MARK: - Collection Performance
    
    @Test("Array search performance")
    func testArraySearchPerformance() async throws {
        let arraySize = 10000
        let testArray = Array(1...arraySize)
        let searchValues = [1, 100, 1000, 5000, 9999, 10000]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for value in searchValues {
            let index = testArray.firstIndex(of: value)
            #expect(index != nil, "Should find value \(value)")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        #expect(timeElapsed < 0.1, "Array search should be reasonably fast")
    }
    
    @Test("Dictionary lookup performance")
    func testDictionaryLookupPerformance() async throws {
        let dictionarySize = 10000
        var testDictionary: [String: Int] = [:]
        
        // Populate dictionary
        for i in 1...dictionarySize {
            testDictionary["key_\(i)"] = i
        }
        
        let searchKeys = ["key_1", "key_100", "key_1000", "key_5000", "key_9999", "key_10000"]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for key in searchKeys {
            let value = testDictionary[key]
            #expect(value != nil, "Should find value for key \(key)")
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        #expect(timeElapsed < 0.01, "Dictionary lookup should be very fast")
    }
    
    // MARK: - Date Performance
    
    @Test("Date creation and comparison performance")
    func testDateCreationAndComparisonPerformance() async throws {
        let dateCount = 1000
        var dates: [Date] = []
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for _ in 0..<dateCount {
            dates.append(Date())
        }
        
        // Sort dates
        dates.sort()
        
        // Compare dates
        var comparisons = 0
        for i in 0..<(dates.count - 1) {
            if dates[i] <= dates[i + 1] {
                comparisons += 1
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        #expect(dates.count == dateCount, "Should create all dates")
        #expect(comparisons == dateCount - 1, "All date comparisons should be valid")
        #expect(timeElapsed < 1.0, "Date operations should be fast")
    }
    
    // MARK: - Mock Repository Performance
    
    @Test("Mock repository operations performance")
    func testMockRepositoryOperationsPerformance() async throws {
        class PerformanceTestRepository: ImportedDocumentRepository {
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
        
        let repository = PerformanceTestRepository()
        let documentCount = 100
        var documentIds: [UUID] = []
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create documents
        for i in 0..<documentCount {
            let document = ImportedDocument(
                id: UUID(),
                name: "Performance_Test_Document_\(i).pdf",
                conversations: [],
                createdAt: Date(),
                updatedAt: Date()
            )
            let created = try await repository.create(entity: document)
            documentIds.append(created.id!)
        }
        
        // Read documents
        for id in documentIds {
            let doc = try await repository.read(id: id)
            #expect(doc != nil, "Should read created document")
        }
        
        // List all documents
        let allDocs = try await repository.list()
        #expect(allDocs.count == documentCount, "Should list all documents")
        
        // Delete some documents
        for id in documentIds.prefix(10) {
            try await repository.delete(id: id)
        }
        
        let remainingDocs = try await repository.list()
        #expect(remainingDocs.count == documentCount - 10, "Should have correct number of remaining documents")
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        #expect(timeElapsed < 2.0, "Repository operations should complete within 2 seconds")
    }
    
    // MARK: - Concurrency Performance
    
    @Test("Concurrent operations performance")
    func testConcurrentOperationsPerformance() async throws {
        let operationCount = 100
        let startTime = CFAbsoluteTimeGetCurrent()
        
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<operationCount {
                group.addTask {
                    // Simulate concurrent work
                    let document = ImportedDocument(
                        id: UUID(),
                        name: "Concurrent_Document_\(i).pdf",
                        conversations: [],
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    // Perform some work with the document
                    let _ = document.name?.count ?? 0
                    let _ = document.id?.uuidString ?? ""
                }
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let timeElapsed = endTime - startTime
        
        // More lenient timing for CI environments - allow up to 5 seconds
        // This accounts for resource constraints and virtualization overhead in CI
        #expect(timeElapsed < 5.0, "Concurrent operations should complete within reasonable time (elapsed: \(timeElapsed)s)")
    }
}
