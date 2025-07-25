//
//  NaturalLanguageChunkEmbeddingRepository.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 23/07/25.
//

import NaturalLanguage
import Foundation

/// An actor that manages embeddings using Apple's NaturalLanguage framework
/// This provides built-in word and sentence embeddings without requiring external models.
actor NaturalLanguageChunkEmbeddingRepository: ChunkEmbeddingRepository {
    
  
    func embed(chunk: EmbeddableChunk) async -> EmbeddedChunk {
        let ragSystem = NLRAGSystem()
        ragSystem.addDocument(chunk.embeddedChunk)
        return ragSystem.documents.first!
    }
    
    func embed(chunks: [EmbeddableChunk]) async -> [EmbeddedChunk] {
        let ragSystem = NLRAGSystem()
          for chunk in chunks {
            ragSystem.addDocument(chunk.embeddedChunk)
        }
        return ragSystem.documents
    }
    
    func searchRelevantChunk(for query: String, chunks: [EmbeddedChunk], limit: Int) async -> [EmbeddedChunk] {
        let ragSystem = NLRAGSystem(documents: chunks)
        return ragSystem.searchRelevantDocuments(for: query, limit: limit)
    }

}


