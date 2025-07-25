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

    private lazy var importedDocumentsRepository: any ImportedDocumentRepository = Container.shared
        .importedDocumentRepository()

    // Published properties for UI binding
    @Published var isImporting: Bool = false
    @Published var importError: Error?
    @Published var importProgress: Double = 0.0
    @Published public var documents: [ImportedDocument] = []

    init() {
        Task { [weak self] in
            guard let self = self else { return }
            let docs = try! await importedDocumentsRepository.list()
            DispatchQueue.main.async {
                self.documents = docs
            }
        }
    }

    /// Import document flow: generates chunks, embeds, and stores them
    func importDocument(from fileURL: URL) async {
               DispatchQueue.main.async {
                   self.isImporting = true
                   self.importError = nil
                   self.importProgress = 0.0
               }

               let text = await documentContentExtractor.extractContent(from: fileURL) ?? ""
        let docId = UUID()
               let chunks = await chunkGenerator.generateChunks(documentID: docId, from: text)
               let total = Double(chunks.count)
        let embedded = await chunkEmbedder.embed(chunks: chunks)
              _ = await vectorStore.store(embedded: embedded, for: docId)
               
        let now = Date()
        let importedDocument = ImportedDocument(
            id: docId,
            name: fileURL.lastPathComponent,
            conversations: [],
            createdAt: now,
            updatedAt: now
        )
        _ = try! await importedDocumentsRepository.create(entity: importedDocument)

        DispatchQueue.main.async {
            self.isImporting = false
            // Append the new document to the documents array to update the view state
            self.documents.append(importedDocument)
        }
    }
}
