//
//  doc_botTests.swift
//  doc-botTests
//
//  Created by LUIZ FELIPE ALVES LIMA on 20/07/25.
//

import Testing
@testable import doc_bot
import Foundation

@MainActor
struct doc_botTests {
    
    // MARK: - Model Tests
    
    @Test("ImportedDocument creation with all properties")
    func testImportedDocumentCreation() async throws {
        let id = UUID()
        let name = "Test Document.pdf"
        let now = Date()
        let conversations: [ChatConversation] = []
        
        let document = ImportedDocument(
            id: id,
            name: name,
            conversations: conversations,
            createdAt: now,
            updatedAt: now
        )
        
        #expect(document.id == id)
        #expect(document.name == name)
        #expect(document.conversations?.isEmpty == true)
        #expect(document.createdAt == now)
        #expect(document.updatedAt == now)
    }
    
    @Test("ChatMessage creation with user role")
    func testChatMessageCreation() async throws {
        let id = UUID()
        let content = "Hello, how can I help you?"
        let now = Date()
        
        let message = ChatMessage(
            id: id,
            role: .user,
            content: content,
            createdAt: now,
            updatedAt: now,
            conversation: nil
        )
        
        #expect(message.id == id)
        #expect(message.role == .user)
        #expect(message.content == content)
        #expect(message.createdAt == now)
        #expect(message.updatedAt == now)
        #expect(message.conversation == nil)
    }
    
    @Test("PdfMessageRole enum values")
    func testPdfMessageRoleValues() async throws {
        #expect(PdfMessageRole.user.rawValue == "user")
        #expect(PdfMessageRole.assistant.rawValue == "assistant")
    }
    
    // MARK: - EmbeddableChunk Tests
    
    @Test("EmbeddableChunk creation generates unique ID")
    func testEmbeddableChunkCreation() async throws {
        let documentID = UUID()
        let content = "This is a test chunk of text."
        
        let chunk1 = EmbeddableChunk(content: content, documentID: documentID)
        let chunk2 = EmbeddableChunk(content: content, documentID: documentID)
        
        #expect(chunk1.content == content)
        #expect(chunk1.documentID == documentID)
        #expect(chunk1.id != chunk2.id) // IDs should be unique
    }
    
    @Test("EmbeddedChunk creation")
    func testEmbeddedChunkCreation() async throws {
        let id = UUID()
        let documentID = UUID()
        let content = "Test content for embedding"

        let documentChunk = DocumentChunk(text: content, pageNumber: 0)
        let embeddedChunk = EmbeddedChunk(id: id, documentChunk: documentChunk, documentID: documentID)
        
        #expect(embeddedChunk.id == id)
        #expect(embeddedChunk.documentID == documentID)
        #expect(embeddedChunk.content == content)
        #expect(embeddedChunk.embedding == nil) // Should be nil initially
    }
    
    // MARK: - Error Handling Tests
    
    @Test("EmbeddingError descriptions")
    func testEmbeddingErrorDescriptions() async throws {
        #expect(EmbeddingError.noEmbeddingAvailable.localizedDescription == "No embedding model available for the specified language")
        #expect(EmbeddingError.noWordsFound.localizedDescription == "No valid words found in the input text")
        #expect(EmbeddingError.invalidText.localizedDescription == "The input text is invalid or empty")
    }
    
    // MARK: - Array Extension Tests
    
    @Test("Array chunked method with valid input")
    func testArrayChunkedMethod() async throws {
        let array = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let chunked = array.chunked(into: 3)
        
        #expect(chunked.count == 4)
        #expect(chunked[0] == [1, 2, 3])
        #expect(chunked[1] == [4, 5, 6])
        #expect(chunked[2] == [7, 8, 9])
        #expect(chunked[3] == [10])
    }
    
    @Test("Array chunked method with empty array")
    func testArrayChunkedMethodEmpty() async throws {
        let array: [Int] = []
        let chunked = array.chunked(into: 3)
        
        #expect(chunked.isEmpty)
    }
    
    @Test("Array chunked method with size larger than array")
    func testArrayChunkedMethodLargeSize() async throws {
        let array = [1, 2, 3]
        let chunked = array.chunked(into: 5)
        
        #expect(chunked.count == 1)
        #expect(chunked[0] == [1, 2, 3])
    }
}
