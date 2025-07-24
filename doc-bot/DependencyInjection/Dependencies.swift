import Factory

extension Container {
    var chunkGeneratorRepository: Factory<ChunkGeneratorRepository> {
        Factory(self) { NaturalLanguageChunkGenerator() }
    }

    var chunkEmbeddingRepository: Factory<ChunkEmbeddingRepository> {
        Factory(self) { NaturalLanguageChunkEmbeddingRepository() }
    }

    var vectorChunkRepository: Factory<VectorChunkRepository> {
        Factory(self) { NaturalLanguageVectorRepository()}
    }

    var documentContentExtractor: Factory<DocumentContentExtractor> {
        Factory(self) { PdfKitDocumentContentExtractor() }
    }

    var importedDocumentsViewModel: Factory<ImportedDocumentsViewModel> {
        Factory(self) { @MainActor in ImportedDocumentsViewModel() }
    }

    var completionRepository: Factory<CompletionRepository> {
        Factory(self) { LlamaCompletionRepository() }
    }

    var modelDownloaderRepository: Factory<ModelDownloaderRepository> {
        Factory(self) {
            ConcreteModelDownloaderRepository()
        }
    }


    var importedDocumentRepository: Factory<any ImportedDocumentRepository> {
        Factory(self) {
            let context = PersistenceController.shared.container.viewContext
            return CoreDataImportedDocumentRepository(context: context)
        }.scope(.shared)
    }


    var conversationMessageRepository: Factory<any ConversationMessageRepository> {
        Factory(self) {
            let context = PersistenceController.shared.container.viewContext
            return CoreDataConversationMessageRepository(context: context)
        }.scope(.shared)
    }

    var conversationRepository: Factory<any ConversationRepository> {
        Factory(self) {
            let context = PersistenceController.shared.container.viewContext
            return CoreDataConversationRepository(context: context)
        }.scope(.shared)
    }

    var promptContextGenerator: Factory<PromptContextGenerator> {
        Factory(self) { PromptContextGeneratorImpl() }
    }
}
