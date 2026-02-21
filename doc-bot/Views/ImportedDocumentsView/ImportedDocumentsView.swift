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
                    ChatView(documentId: document.id!)
                }
                .alert(item: $importErrorWrapper) { wrapper in
                    Alert(
                        title: Text(Constants.errorAlertTitle),
                        message: Text(wrapper.error.localizedDescription),
                        dismissButton: .default(Text(LocalizedString.buttonOK))
                    )
                }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.loadingContent {
                loadingContentView
            } else if viewModel.documents.isEmpty {
                emptyStateView
            } else {
                documentListView
            }

            if viewModel.isImporting {
                importingOverlay
            }
        }
        .animation(.easeInOut, value: viewModel.loadingContent)
        .animation(.easeInOut, value: viewModel.documents.isEmpty)
        .animation(.easeInOut, value: viewModel.isImporting)
    }

    private var documentListView: some View {
        List(viewModel.documents) { document in
            NavigationLink(value: document) {
                DocumentRowView(document: document)
            }
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .buttonStyle(PlainButtonStyle())
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 16)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                
                Image(systemName: Constants.emptyStateIcon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 8) {
                Text(Constants.emptyStateTitle)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Text(Constants.emptyStateSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .transition(.opacity)
    }

    private var loadingContentView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                .scaleEffect(1.2)
            
            Text(Constants.loadingContentText)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .transition(.opacity)
    }

    private var importingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView(value: viewModel.importProgress)
                    .progressViewStyle(.linear)
                    .tint(.accentColor)
                    .scaleEffect(x: 1, y: 1.5)
                
                Text(Constants.importingText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.primary)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 40)
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.8)),
            removal: .opacity
        ))
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showingImporter = true
            } label: {
                Image(systemName: Constants.importButtonIcon)
                    .font(.system(size: 18, weight: .medium))
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
        static let navTitle = LocalizedString.navDocuments
        static let importButtonLabel = LocalizedString.buttonImport
        static let importButtonIcon = "doc.badge.plus"
        static let documentIcon = "doc.text.fill"
        static let emptyStateIcon = "doc.on.doc.fill"
        static let emptyStateTitle = LocalizedString.documentsEmptyTitle
        static let emptyStateSubtitle = LocalizedString.documentsEmptySubtitle
        static let importingText = LocalizedString.documentsImporting
        static let loadingContentText = LocalizedString.documentsLoading
        static let errorAlertTitle = LocalizedString.alertErrorTitle
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
            func generateChunks(documentID: UUID, from pages: [DocumentPageContent]) async -> [EmbeddableChunk] {
                []
            }
        }
        class MockChunkEmbedder: ChunkEmbeddingRepository {
            func embed(chunk: EmbeddableChunk) async -> EmbeddedChunk {
                return .init(id: UUID(), documentChunk: DocumentChunk(text: "", pageNumber: 0), documentID: .init())
            }
            
            func embed(chunks: [EmbeddableChunk]) async -> [EmbeddedChunk] {
                []
            }
            
            func searchRelevantChunk(
                for query: String,
                chunks: [EmbeddedChunk],
                limit: Int,
                minimumScore: Double
            ) async -> [EmbeddedChunk] {
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
            func extractContent(from fileURL: URL) async -> [DocumentPageContent]? { [] }
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
            
            override var loadingContent: Bool {
                get { false }
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
