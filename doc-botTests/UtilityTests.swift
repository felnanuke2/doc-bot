//
//  UtilityTests.swift
//  doc-botTests
//
//  Created by Unit Tests on 03/08/25.
//

import Testing
@testable import doc_bot
import Foundation

struct UtilityTests {
    
    // MARK: - Array Extensions Tests
    
    @Test("Array chunked extension with normal case")
    func testArrayChunkedNormalCase() async throws {
        let array = Array(1...10)
        let chunks = array.chunked(into: 3)
        
        #expect(chunks.count == 4, "Should create 4 chunks")
        #expect(chunks[0] == [1, 2, 3], "First chunk should be [1, 2, 3]")
        #expect(chunks[1] == [4, 5, 6], "Second chunk should be [4, 5, 6]")
        #expect(chunks[2] == [7, 8, 9], "Third chunk should be [7, 8, 9]")
        #expect(chunks[3] == [10], "Fourth chunk should be [10]")
    }
    
    @Test("Array chunked extension with empty array")
    func testArrayChunkedEmptyArray() async throws {
        let array: [Int] = []
        let chunks = array.chunked(into: 5)
        
        #expect(chunks.isEmpty, "Empty array should produce empty chunks")
    }
    
    @Test("Array chunked extension with single element")
    func testArrayChunkedSingleElement() async throws {
        let array = [42]
        let chunks = array.chunked(into: 3)
        
        #expect(chunks.count == 1, "Should create 1 chunk")
        #expect(chunks[0] == [42], "Chunk should contain single element")
    }
    
    @Test("Array chunked extension with chunk size larger than array")
    func testArrayChunkedLargeChunkSize() async throws {
        let array = [1, 2, 3]
        let chunks = array.chunked(into: 10)
        
        #expect(chunks.count == 1, "Should create 1 chunk")
        #expect(chunks[0] == [1, 2, 3], "Chunk should contain all elements")
    }
    
    @Test("Array chunked extension with chunk size of 1")
    func testArrayChunkedChunkSizeOne() async throws {
        let array = [1, 2, 3, 4]
        let chunks = array.chunked(into: 1)
        
        #expect(chunks.count == 4, "Should create 4 chunks")
        #expect(chunks[0] == [1], "First chunk should be [1]")
        #expect(chunks[1] == [2], "Second chunk should be [2]")
        #expect(chunks[2] == [3], "Third chunk should be [3]")
        #expect(chunks[3] == [4], "Fourth chunk should be [4]")
    }
    
    @Test("Array chunked extension with strings")
    func testArrayChunkedWithStrings() async throws {
        let array = ["a", "b", "c", "d", "e", "f", "g"]
        let chunks = array.chunked(into: 3)
        
        #expect(chunks.count == 3, "Should create 3 chunks")
        #expect(chunks[0] == ["a", "b", "c"], "First chunk should be correct")
        #expect(chunks[1] == ["d", "e", "f"], "Second chunk should be correct")
        #expect(chunks[2] == ["g"], "Third chunk should be correct")
    }
    
    // MARK: - LocalizedString Tests
    
    @Test("LocalizedString returns non-empty strings")
    func testLocalizedStringReturnsNonEmptyStrings() async throws {
        // Test some key localized strings
        #expect(!LocalizedString.buttonOK.isEmpty, "OK button text should not be empty")
        #expect(!LocalizedString.navDocuments.isEmpty, "Documents navigation title should not be empty")
        #expect(!LocalizedString.buttonImport.isEmpty, "Import button text should not be empty")
        #expect(!LocalizedString.documentsEmptyTitle.isEmpty, "Empty state title should not be empty")
        #expect(!LocalizedString.documentsEmptySubtitle.isEmpty, "Empty state subtitle should not be empty")
        #expect(!LocalizedString.documentsImporting.isEmpty, "Importing text should not be empty")
        #expect(!LocalizedString.documentsLoading.isEmpty, "Loading text should not be empty")
        #expect(!LocalizedString.alertErrorTitle.isEmpty, "Error alert title should not be empty")
    }
    
    @Test("LocalizedString values are reasonable")
    func testLocalizedStringValuesAreReasonable() async throws {
        // Test that localized strings contain expected content (basic sanity checks)
        #expect(LocalizedString.buttonOK.lowercased().contains("ok") || 
                LocalizedString.buttonOK.lowercased().contains("sim") || 
                LocalizedString.buttonOK.lowercased().contains("vale"), 
                "OK button should contain recognizable text")
        
        #expect(LocalizedString.navDocuments.lowercased().contains("document") || 
                LocalizedString.navDocuments.lowercased().contains("archivo") || 
                LocalizedString.navDocuments.lowercased().contains("documento"), 
                "Documents title should contain recognizable text")
        
        #expect(LocalizedString.buttonImport.lowercased().contains("import") || 
                LocalizedString.buttonImport.lowercased().contains("adicionar") || 
                LocalizedString.buttonImport.lowercased().contains("agregar"), 
                "Import button should contain recognizable text")
    }
    
    // MARK: - PDFParser Tests
    
    @Test("PDFParser instantiation")
    func testPDFParserInstantiation() async throws {
        let parser = PDFParser()
        
        // Since PDFParser is currently just a placeholder, we can only test instantiation
        #expect(parser != nil, "PDFParser should be instantiable")
    }
    
    // MARK: - Model Tests
    
    @Test("ImportedDocument equality")
    func testImportedDocumentEquality() async throws {
        let id = UUID()
        let name = "Test.pdf"
        let date = Date()
        
        let doc1 = ImportedDocument(
            id: id, 
            name: name, 
            conversations: [], 
            createdAt: date, 
            updatedAt: date
        )
        
        let doc2 = ImportedDocument(
            id: id, 
            name: name, 
            conversations: [], 
            createdAt: date, 
            updatedAt: date
        )
        
        #expect(doc1 == doc2, "Documents with same properties should be equal")
    }
    
    @Test("ImportedDocument inequality")
    func testImportedDocumentInequality() async throws {
        let date = Date()
        
        let doc1 = ImportedDocument(
            id: UUID(), 
            name: "Test1.pdf", 
            conversations: [], 
            createdAt: date, 
            updatedAt: date
        )
        
        let doc2 = ImportedDocument(
            id: UUID(), 
            name: "Test2.pdf", 
            conversations: [], 
            createdAt: date, 
            updatedAt: date
        )
        
        #expect(doc1 != doc2, "Documents with different IDs should not be equal")
    }
    
    @Test("ChatMessage creation and properties")
    func testChatMessageCreationAndProperties() async throws {
        let id = UUID()
        let content = "Hello, world!"
        let createdAt = Date()
        let updatedAt = Date()
        
        let message = ChatMessage(
            id: id,
            role: .user,
            content: content,
            createdAt: createdAt,
            updatedAt: updatedAt,
            conversation: nil
        )
        
        #expect(message.id == id, "Message ID should match")
        #expect(message.role == .user, "Message role should be user")
        #expect(message.content == content, "Message content should match")
        #expect(message.createdAt == createdAt, "Created date should match")
        #expect(message.updatedAt == updatedAt, "Updated date should match")
        #expect(message.conversation == nil, "Conversation should be nil")
    }
    
    @Test("PdfMessageRole string conversion")
    func testPdfMessageRoleStringConversion() async throws {
        #expect(PdfMessageRole.user.rawValue == "user", "User role raw value should be 'user'")
        #expect(PdfMessageRole.assistant.rawValue == "assistant", "Assistant role raw value should be 'assistant'")
        
        // Test round-trip conversion
        let userRole = PdfMessageRole(rawValue: "user")
        let assistantRole = PdfMessageRole(rawValue: "assistant")
        let invalidRole = PdfMessageRole(rawValue: "invalid")
        
        #expect(userRole == .user, "Should parse 'user' correctly")
        #expect(assistantRole == .assistant, "Should parse 'assistant' correctly")
        #expect(invalidRole == nil, "Should return nil for invalid role")
    }
    
    // MARK: - EmbeddableChunk Tests
    
    @Test("EmbeddableChunk ID uniqueness")
    func testEmbeddableChunkIDUniqueness() async throws {
        let documentID = UUID()
        let content = "Test content"
        
        let chunk1 = EmbeddableChunk(content: content, documentID: documentID)
        let chunk2 = EmbeddableChunk(content: content, documentID: documentID)
        
        #expect(chunk1.id != chunk2.id, "Each chunk should have unique ID")
        #expect(chunk1.content == chunk2.content, "Content should be the same")
        #expect(chunk1.documentID == chunk2.documentID, "Document ID should be the same")
    }
    
    @Test("EmbeddableChunk embeddedChunk conversion")
    func testEmbeddableChunkEmbeddedChunkConversion() async throws {
        let documentID = UUID()
        let content = "Test content for embedding"
        
        let embeddableChunk = EmbeddableChunk(content: content, documentID: documentID)
        let embeddedChunk = embeddableChunk.embeddedChunk
        
        #expect(embeddedChunk.id == embeddableChunk.id, "IDs should match")
        #expect(embeddedChunk.content == embeddableChunk.content, "Content should match")
        #expect(embeddedChunk.documentID == embeddableChunk.documentID, "Document IDs should match")
        #expect(embeddedChunk.embedding == nil, "Embedding should be nil initially")
    }
    
    @Test("EmbeddedChunk properties")
    func testEmbeddedChunkProperties() async throws {
        let id = UUID()
        let documentID = UUID()
        let content = "Test embedded content"

        let documentChunk = DocumentChunk(text: content, pageNumber: 0)
        let embeddedChunk = EmbeddedChunk(id: id, documentChunk: documentChunk, documentID: documentID)
        
        #expect(embeddedChunk.id == id, "ID should match")
        #expect(embeddedChunk.content == content, "Content should match")
        #expect(embeddedChunk.documentID == documentID, "Document ID should match")
        #expect(embeddedChunk.embedding == nil, "Embedding should be nil initially")
        
        // Test setting embedding
        let testEmbedding = [0.1, 0.2, 0.3, 0.4, 0.5]
        embeddedChunk.embedding = testEmbedding
        
        #expect(embeddedChunk.embedding == testEmbedding, "Embedding should be set correctly")
    }
    
    // MARK: - Error Handling Tests
    
    @Test("EmbeddingError cases and descriptions")
    func testEmbeddingErrorCasesAndDescriptions() async throws {
        let noEmbeddingError = EmbeddingError.noEmbeddingAvailable
        let noWordsError = EmbeddingError.noWordsFound
        let invalidTextError = EmbeddingError.invalidText
        
        #expect(noEmbeddingError.localizedDescription == "No embedding model available for the specified language")
        #expect(noWordsError.localizedDescription == "No valid words found in the input text")
        #expect(invalidTextError.localizedDescription == "The input text is invalid or empty")
        
        // Test that errors are different
        #expect(noEmbeddingError != noWordsError)
        #expect(noWordsError != invalidTextError)
        #expect(invalidTextError != noEmbeddingError)
    }
}
