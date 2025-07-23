import SwiftUI
import UniformTypeIdentifiers
import Factory


struct ImportedDocumentsView: View {
    @InjectedObject(\.importedDocumentsViewModel) var viewModel: ImportedDocumentsViewModel
    @State private var showingImporter = false
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Your Documents")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingImporter = true }) {
                            Label("Import Document", systemImage: "plus.circle.fill")
                                .font(.title3)
                        }
                    }
                }
                .fileImporter(
                    isPresented: $showingImporter,
                    allowedContentTypes: [UTType.pdf],
                    allowsMultipleSelection: false
                ) { result in
                    switch result {
                    case .success(let urls):
                        if let url = urls.first {
                            Task {
                                await viewModel.importDocument(from: url)
                            }
                        }
                    case .failure(let error):
                        // Optionally handle error
                        print("Import error: \(error)")
                    }
                }
                .navigationDestination(for: ImportedDocument.self) { document in
                    Text("Detail view for \(document.name)")
                }
        }
    }
    
    // Using a @ViewBuilder to cleanly switch between the list and an empty state.
    @ViewBuilder
    private var mainContent: some View {
        // You may want to add a loading/progress indicator using viewModel.isImporting
        if viewModel.documents.isEmpty {
            emptyStateView
        } else {
            documentListView
        }
        
        if viewModel.isImporting {
            ZStack {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                VStack(spacing: 20) {
                    ProgressView(value: viewModel.importProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .accentColor))
                        .scaleEffect(x: 1.2, y: 1.2, anchor: .center)
                        .padding(.horizontal, 32)
                    Text("Importing document...")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.top, 4)
                }
                .padding(32)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .opacity(0.95)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.15), lineWidth: 1)
                )
                .shadow(radius: 16, y: 4)
            }
            .transition(.opacity)
        }
    }
    
    // A polished list with improved row design.
    private var documentListView: some View {
        List(viewModel.documents) { document in
            NavigationLink(value: document) {
                HStack(spacing: 16) {
                    Image(systemName: "doc.text.fill")
                        .font(.title)
                        .foregroundStyle(.red)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.name)
                            .fontWeight(.medium)
                            .lineLimit(2)
                        Text("Conversations: \(document.conversations.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
    }
    
    // A dedicated view to guide the user when the list is empty.
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.on.doc.fill")
                .font(.system(size: 70))
                .foregroundStyle(Color.gray.opacity(0.6))
            Text("No Documents Yet")
                .font(.title2.bold())
            Text("Tap the '+' icon to import a Document.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Center the content
        .transition(.opacity.animation(.easeInOut))
    }
    

}

// MARK: - Preview
struct ImportedDocumentsView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock dependencies for the view model
        class MockChunkGenerator: ChunkGeneratorRepository {
            func generateChunks(documentID: UUID, from text: String) async -> [EmbeddableChunk] { [] }
        }
        class MockChunkEmbedder: ChunkEmbeddingRepository {
            func embed(chunk: EmbeddableChunk, with localModel: LocalModel) async -> [Float] { [] }
            func embed(chunks: [EmbeddableChunk], with model: LocalModel) async -> [[Float]] { 
                return chunks.map { _ in [] } 
            }
        }
        class MockVectorStore: VectorChunkRepository {
            func addChunk(_ chunks: [(EmbeddableChunk, [Float])]) async {
                
            }
            
            func closestChunks(documentID: UUID, to embedding: [[Float]], topK: Int) async -> [StoredChunk] { [] }
            
            func addChunk(_ chunk: EmbeddableChunk, embedding: [Float]) async { }
        }
        class MockContentExtractor: DocumentContentExtractor {
            func extractContent(from fileURL: URL) async -> String? { "" }
        }
        class MockCompletionRepository: CompletionRepository {
            func generateCompletion(for prompt: String) -> AsyncStream<CompletionResult> {
                AsyncStream {completion in
                    completion.yield(.finished("asas"))
                    completion.finish()
                }
            }
            
         
        }
        class MockViewModel: ImportedDocumentsViewModel {
            override var documents: [ImportedDocument] {
                get {
                    [
                        ImportedDocument(id: UUID(), name: "Car Manual.pdf", conversations: [], createdAt: Date(), updatedAt: Date()),
                        ImportedDocument(id: UUID(), name: "SwiftUI Guide.pdf", conversations: [], createdAt: Date(), updatedAt: Date()),
                        ImportedDocument(id: UUID(), name: "Project Proposal.pdf", conversations: [], createdAt: Date(), updatedAt: Date())
                    ]
                }
                set {}
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
                // Return a mock local URL for the model
                return URL(fileURLWithPath: "/mock/path/to/model")
            }
            
            
        }

        // Register mock services for preview
        Container.shared.chunkGeneratorRepository.register { MockChunkGenerator() }
        Container.shared.chunkEmbeddingRepository.register { MockChunkEmbedder() }
        Container.shared.vectorChunkRepository.register { MockVectorStore() }
        Container.shared.documentContentExtractor.register { MockContentExtractor() }
        Container.shared.completionRepository.register { MockCompletionRepository() }
        Container.shared.modelDownloaderRepository.register { MockModelDownloaderRepository() }

        // Register the mock view model in the DI container
        Container.shared.importedDocumentsViewModel.register {
            MockViewModel.init()
        }

        // Resolve the view model from the DI container
        return ImportedDocumentsView()
    }
}
