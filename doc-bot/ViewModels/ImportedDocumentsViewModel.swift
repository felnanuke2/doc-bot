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
    @Published public var embeddingModel = embeddModels[0]
    @Published public var embeddingLocalModel: LocalModel?

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
               var embeddingLocalModel = self.embeddingLocalModel
               if embeddingLocalModel == nil {
                   embeddingLocalModel = await downloadLocalModel(embeddingModel)
                   // If still nil, exit early
                   guard let model = embeddingLocalModel else {
                       DispatchQueue.main.async {
                           self.isImporting = false
                           self.importError = NSError(
                               domain: "ImportError", code: 1,
                               userInfo: [NSLocalizedDescriptionKey: "Failed to download embedding model."]
                           )
                       }
                       return
                   }
                   embeddingLocalModel = model
               }

//        Process chunks in batches for dramatically improved performance
        let batchSize = 32  // Optimal batch size - adjust based on memory constraints
               let chunkBatches = chunks.chunked(into: batchSize)
               var pairs: [(EmbeddableChunk, [Float])] = []
               for (batchIndex, batch) in chunkBatches.enumerated() {
                   // Process an entire batch in one call - this is much faster!
                   let embeddings = await chunkEmbedder.embed(chunks: batch, with: embeddingLocalModel!)
                   // Prepare tuples for batch add
                   pairs.append(contentsOf: zip(batch, embeddings))
                   // Update progress based on processed batches
                   DispatchQueue.main.async {
                       let processedCount = (batchIndex * batchSize) + batch.count
                       // Scale progress from 0.1 to 1.0 (since 0.0-0.1 is reserved for model download)
                       let embeddingProgress = Double(processedCount) / total
                       self.importProgress = 0.1 + (embeddingProgress * 0.9)
                   }
               }
               await vectorStore.addChunk(pairs)
        
               // After storing vectors, create and persist the document
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

    private func downloadLocalModel(_ model: Model) async -> LocalModel {
//        var localModel: LocalModel?
//        var localModel: LocalModel?
        return LocalModel(localPath: URL(string: "abc.guff")!)
//        for await event in modelDownloaderRepository.downloadModel(from: URL(string: model.url)!) {
//            switch event {
//            case .waiting:
//                print("Waiting for model download to start...")
//            case .progressing(let progress):
//                DispatchQueue.main.async {
//                    // Use a different progress indicator for model download vs embedding generation
//                    // This prevents interference with batch processing progress
//                    self.importProgress = progress * 0.1  // Use 10% of progress bar for model download
//                }
//                print("Downloading model: \(progress * 100)%")
//            case .finished(let url):
//                print("Model downloaded successfully to \(url.path)")
//                localModel = LocalModel(localPath: url)
//                DispatchQueue.main.async {
//                    self.importProgress = 0.1  // Model download complete, ready for embedding
//                }
//            case .failure(let error):
//                DispatchQueue.main.async {
//                    self.importError = error
//                }
//                print("Failed to download model: \(error.localizedDescription)")
//            }
//        }
//
//        return localModel!
    }
}
