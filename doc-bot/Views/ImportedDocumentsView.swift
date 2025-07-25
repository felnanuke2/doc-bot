import Factory
import SwiftUI
import UniformTypeIdentifiers

struct ImportedDocumentsView: View {
    // MARK: - Properties

    @InjectedObject(\.importedDocumentsViewModel) private var viewModel
    @State private var showingImporter = false
    @State private var importErrorWrapper: ImportErrorWrapper?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle(Constants.navTitle)
                .toolbar { toolbarContent }
                .fileImporter(
                    isPresented: $showingImporter,
                    allowedContentTypes: [.pdf],
                    allowsMultipleSelection: false,
                    onCompletion: handleFileImport
                )
                .navigationDestination(for: ImportedDocument.self) { document in
                    // Directly pass PdfConversation to ChatView
                    ChatView(conversation: PdfConversation(id: UUID(), messages: [], createdAt: .now, updatedAt: .now, document: document ))
                }
                .alert(item: $importErrorWrapper) { wrapper in
                    Alert(
                        title: Text(Constants.errorAlertTitle),
                        message: Text(wrapper.error.localizedDescription),
                        dismissButton: .default(Text("OK"))
                    )
                }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            if viewModel.documents.isEmpty {
                emptyStateView
            } else {
                documentListView
            }

            if viewModel.isImporting {
                importingOverlay
            }
        }
        .animation(.easeInOut, value: viewModel.documents.isEmpty)
        .animation(.easeInOut, value: viewModel.isImporting)
    }

    private var documentListView: some View {
        List(viewModel.documents) { document in
            NavigationLink(value: document) {
                HStack(spacing: 16) {
                    Image(systemName: Constants.documentIcon)
                        .font(.title)
                        .foregroundStyle(.red)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(document.name ?? "Untitled Document")
                            .fontWeight(.medium)
                            .lineLimit(2)
                        Text("Conversations: \(document.conversations?.count ?? 0)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: Constants.emptyStateIcon)
                .font(.system(size: 70))
                .foregroundStyle(.gray.opacity(0.6))

            Text(Constants.emptyStateTitle)
                .font(.title2.bold())
            
            Text(Constants.emptyStateSubtitle)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }

    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.2).ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView(value: viewModel.importProgress)
                    .progressViewStyle(.linear)
                Text(Constants.importingText)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .padding(32)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 10)
        }
        .transition(.opacity)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingImporter = true
            } label: {
                Label(Constants.importButtonLabel, systemImage: Constants.importButtonIcon)
            }
        }
    }

    // MARK: - Private Helpers

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            // Ensure the URL is accessible before processing
            guard url.startAccessingSecurityScopedResource() else {
                // Optionally handle the case where access is denied
                url.stopAccessingSecurityScopedResource()
                return
            }
            Task {
                await viewModel.importDocument(from: url)
                url.stopAccessingSecurityScopedResource()
            }
        case .failure(let error):
            self.importErrorWrapper = ImportErrorWrapper(error: error)
            print("Import failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Helper Types

private extension ImportedDocumentsView {
    enum Constants {
        static let navTitle = "Your Documents"
        static let importButtonLabel = "Import Document"
        static let importButtonIcon = "plus.circle.fill"
        static let documentIcon = "doc.text.fill"
        static let emptyStateIcon = "doc.on.doc.fill"
        static let emptyStateTitle = "No Documents Yet"
        static let emptyStateSubtitle = "Tap the '+' icon to import a new PDF document."
        static let importingText = "Importing document..."
        static let errorAlertTitle = "Import Failed"
    }

    struct ImportErrorWrapper: Identifiable {
        let id = UUID()
        let error: Error
    }
}

// MARK: - Preview
struct ImportedDocumentsView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide mock dependencies for the view model
        class MockChunkGenerator: ChunkGeneratorRepository {
            func generateChunks(documentID: UUID, from text: String) async -> [EmbeddableChunk] {
                []
            }
        }
        class MockChunkEmbedder: ChunkEmbeddingRepository {
            func embed(chunk: EmbeddableChunk) async -> EmbeddedChunk {
                return .init(id: UUID(), content: "", documentID: .init())
            }
            
            func embed(chunks: [EmbeddableChunk]) async -> [EmbeddedChunk] {
                []
            }
            
            func searchRelevantChunk(for query: String, chunks: [EmbeddedChunk], limit: Int) async -> [EmbeddedChunk] {
                []
            }
            
          
        }
        class MockVectorStore: VectorChunkRepository {
            func store(embedded: [EmbeddedChunk], for documentID: UUID) async {
                
            }
            
            func restoreEmbeddings(for documentID: UUID) async -> [EmbeddedChunk]? {
                []
            }
            
           
        }
        class MockContentExtractor: DocumentContentExtractor {
            func extractContent(from fileURL: URL) async -> String? { "" }
        }
        class MockCompletionRepository: CompletionRepository {
            
            
            func generateCompletion(context: any ContextualPrompt, cancellationToken: CancellationToken?) -> AsyncThrowingStream<CompletionResult, any Error> {
                AsyncThrowingStream {continuation in
                    continuation.finish()
                }
            }
            
          
            
            func generateCompletion(for prompt: String, cancellationToken: CancellationToken?) -> AsyncThrowingStream<CompletionResult, Error> {
                AsyncThrowingStream { continuation in
                    continuation.yield(.finished("asas"))
                    continuation.finish()
                }
            }

        }
        class MockViewModel: ImportedDocumentsViewModel {
            override var documents: [ImportedDocument] {
                get {
                    [
                        ImportedDocument(
                            id: UUID(), name: "Car Manual.pdf", conversations: [],
                            createdAt: Date(), updatedAt: Date()),
                        ImportedDocument(
                            id: UUID(), name: "SwiftUI Guide.pdf", conversations: [],
                            createdAt: Date(), updatedAt: Date()),
                        ImportedDocument(
                            id: UUID(), name: "Project Proposal.pdf", conversations: [],
                            createdAt: Date(), updatedAt: Date()),
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

        // Register the mock view model in the DI container, ensuring main actor isolation
        Container.shared.importedDocumentsViewModel.register {
            var viewModel: MockViewModel!
            Task { @MainActor in
                viewModel = MockViewModel()
            }
            // Fallback in case Task doesn't run synchronously in preview
            return viewModel!
        }

        // Resolve the view model from the DI container
        return ImportedDocumentsView()
    }
}
