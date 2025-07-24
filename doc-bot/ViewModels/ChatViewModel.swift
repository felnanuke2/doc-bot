import Combine
import Factory
import Foundation

@MainActor
class ChatViewModel: ObservableObject {
    @Injected(\.chunkGeneratorRepository) private var chunkGenerator: ChunkGeneratorRepository

    @Injected(\.chunkEmbeddingRepository) private var chunkEmbedder: ChunkEmbeddingRepository

    @Injected(\.vectorChunkRepository) private var vectorStore: VectorChunkRepository

    @Injected(\.documentContentExtractor) private var documentContentExtractor:
        DocumentContentExtractor

    @Injected(\.completionRepository) private var completionRepository: CompletionRepository

    @Injected(\.modelDownloaderRepository) private var modelDownloaderRepository:
        ModelDownloaderRepository

    @Injected(\.importedDocumentRepository) private var importedDocumentsRepository:
        any ImportedDocumentRepository

    @Injected(\.promptContextGenerator) private var promptContextGenerator: PromptContextGenerator

    @Published var conversation: PdfConversation
    @Published var newMessageText: String = ""
    @Published var isSending: Bool = false
    @Published var messages: [PdfMessage] = []
    @Published var isProgressing: Bool = false

    private var streamingAssistantMessage: PdfMessage?

    private var cancellationToken: CancellationToken?

    init(conversation: PdfConversation) {
        self.conversation = conversation
        self.messages = conversation.messages
    }
    
    /// Clears all messages in the current conversation and resets state
    func clearChat() {
        cancellationToken?.cancel()
        conversation.messages.removeAll()
        messages.removeAll()
        streamingAssistantMessage = nil
        isSending = false
        isProgressing = false
        newMessageText = ""
    }

    func sendMessage() {
        let trimmed = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userMessage = PdfMessage(
            id: UUID(),
            role: .user,
            content: trimmed,
            createdAt: Date(),
            updatedAt: Date()
        )
        conversation.messages.append(userMessage)
        messages.append(userMessage)
        newMessageText = ""
        isSending = true
        cancellationToken?.cancel()
        cancellationToken = CancellationToken()
        isProgressing = false
        let documentId = conversation.document.id!

        Task {
            let vectors = await chunkEmbedder.embed(
                chunk: EmbeddableChunk(content: trimmed, documentID: documentId),
                with: .defaultModel)
            let topK = await vectorStore.closestChunks(documentID: documentId, to: [vectors], topK: 3)
            let prompt = promptContextGenerator.generateContext(
                for: trimmed, with: topK.map{$0.content}.joined(separator: "\n"))
            await handleCompletionStream(for: prompt, cancellationToken: cancellationToken!)
        }
    }

    func stopStreaming() {
        cancellationToken?.cancel()
    }

    private func handleCompletionStream(
        for context: any ContextualPrompt, cancellationToken: CancellationToken
    )
        async
    {
        do {
            for try await state in self.completionRepository.generateCompletion(
                context: context, cancellationToken: cancellationToken)
            {
                switch state {
                case .waiting:
                    Task { @MainActor in
                        self.isSending = true
                        self.isProgressing = false
                    }
                case .progressing(let partial):
                    Task { @MainActor in
                        self.isProgressing = true
                        if self.streamingAssistantMessage == nil {
                            let assistantMessage = PdfMessage(
                                id: UUID(),
                                role: .assistant,
                                content: partial,
                                createdAt: Date(),
                                updatedAt: Date()
                            )
                            self.streamingAssistantMessage = assistantMessage
                            self.messages.append(assistantMessage)
                        } else if let streaming = self.streamingAssistantMessage {
                            let updatedStreaming = PdfMessage(
                                id: streaming.id,
                                role: streaming.role,
                                content: streaming.content + partial,
                                createdAt: streaming.createdAt,
                                updatedAt: Date()
                            )
                            self.streamingAssistantMessage = updatedStreaming
                            if let idx = self.conversation.messages.lastIndex(where: {
                                $0.id == updatedStreaming.id
                            }) {
                                self.conversation.messages[idx] = updatedStreaming
                            }
                            if let idx = self.messages.lastIndex(where: {
                                $0.id == updatedStreaming.id
                            }) {
                                self.messages[idx] = updatedStreaming
                            }
                        }
                        self.isSending = false
                    }
                case .finished(let final):
                    Task { @MainActor in
                        self.isProgressing = false
                        if let streaming = self.streamingAssistantMessage {
                            let finishedMessage = PdfMessage(
                                id: streaming.id,
                                role: streaming.role,
                                content: final,
                                createdAt: streaming.createdAt,
                                updatedAt: Date()
                            )
                            if let idx = self.conversation.messages.lastIndex(where: {
                                $0.id == streaming.id
                            }) {
                                self.conversation.messages[idx] = finishedMessage
                            }
                            if let idx = self.messages.lastIndex(where: { $0.id == streaming.id }) {
                                self.messages[idx] = finishedMessage
                            }
                        } else {
                            let assistantMessage = PdfMessage(
                                id: UUID(),
                                role: .assistant,
                                content: final,
                                createdAt: Date(),
                                updatedAt: Date()
                            )
                            self.conversation.messages.append(assistantMessage)
                            self.messages.append(assistantMessage)
                        }
                        self.streamingAssistantMessage = nil
                        self.isSending = false
                    }
                case .failure(let error):
                    Task { @MainActor in
                        self.streamingAssistantMessage = nil
                        self.isSending = false
                        self.isProgressing = false
                        print("Completion error: \(error)")
                    }
                }
            }
        } catch {
            Task { @MainActor in
                self.streamingAssistantMessage = nil
                self.isSending = false
                self.isProgressing = false
                print("Error in completion stream: \(error)")
            }
        }
    }
}

extension LocalModel {

    public static let defaultModel = LocalModel(
        localPath: URL(fileURLWithPath: "ggml-model-q8_0.gguf"))
}
