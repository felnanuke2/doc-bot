import Combine
import Factory
import Foundation

// Import CoreDataConversationRepository

@MainActor
class ImportedDocumentsViewModel: ObservableObject {
    @Injected(\.chunkGeneratorRepository) private var chunkGenerator: ChunkGeneratorRepository
    @Injected(\.chunkEmbeddingRepository) private var chunkEmbedder: ChunkEmbeddingRepository
    @Injected(\.vectorChunkRepository) private var vectorStore: VectorChunkRepository
    @Injected(\.documentContentExtractor) private var documentContentExtractor:
        DocumentContentExtractor
    @Injected(\.completionRepository) private var completionRepository: CompletionRepository
    @Injected(\.modelDownloaderRepository) private var modelDownloaderRepository:
        ModelDownloaderRepository
    @Injected(\.importedDocumentRepository) private var importedDocumentsRepository: any ImportedDocumentRepository

    // Published properties for UI binding
    @Published var isImporting: Bool = false
    @Published var importError: Error?
    @Published var importProgress: Double = 0.0
    @Published public var documents: [ImportedDocument] = []
    @Published var loadingContent: Bool = true

    init() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let docs = try await importedDocumentsRepository.list()
                await MainActor.run {
                    self.documents = docs
                    self.loadingContent = false
                }
            } catch {
                await MainActor.run {
                    self.documents = []
                    self.loadingContent = false
                }
            }
        }
    }

    /// Import document flow: generates chunks, embeds, and stores them
    func importDocument(from fileURL: URL) async {
        await MainActor.run {
            self.isImporting = true
            self.importError = nil
            self.importProgress = 0.0
        }

        do {
            let docId = UUID()

            _ = try DocumentFileStore.storeDocument(from: fileURL, documentId: docId)

            let pages = await documentContentExtractor.extractContent(from: fileURL) ?? []
            
            await MainActor.run {
                self.importProgress = 0.25
            }
            
            let chunks = await chunkGenerator.generateChunks(documentID: docId, from: pages)
            
            await MainActor.run {
                self.importProgress = 0.5
            }
            
            let embedded = await chunkEmbedder.embed(chunks: chunks)
            
            await MainActor.run {
                self.importProgress = 0.75
            }
            
            await vectorStore.store(embedded: embedded, for: docId)
               
            let now = Date()
            let importedDocument = ImportedDocument(
                id: docId,
                name: fileURL.lastPathComponent,
                conversations: [],
                createdAt: now,
                updatedAt: now
            )
            
            let createdDocument = try await importedDocumentsRepository.create(entity: importedDocument)

            await MainActor.run {
                self.isImporting = false
                self.importProgress = 0.0
                self.documents.append(createdDocument)
            }
        } catch {
            await MainActor.run {
                self.isImporting = false
                self.importProgress = 0.0
                self.importError = error
            }
        }
    }
}
