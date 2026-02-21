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
    
    @Injected(\.conversationRepository) private var conversationRepository: any ConversationRepository
    
    @Injected(\.conversationMessageRepository) private var conversationMessageRepository: any ConversationMessageRepository
    
    @Injected(\.subjectRepository) private var subjectRepository: SubjectRepository

    @Injected(\.referenceOutput) private var referenceOutput: ReferenceOutput

    @Published var conversation: ChatConversation?
    @Published var newMessageText: String = ""
    @Published var isSending: Bool = false
    @Published var messages: [ChatMessage] = []
    @Published var isProgressing: Bool = false
    @Published var messageReferences: [UUID: [DocumentChunk]] = [:]

    private var streamingAssistantMessage: ChatMessage?
    
    private let documentId: UUID;

    private var cancellationToken: CancellationToken?

    init(conversation: ChatConversation?, documentId: UUID) {
        self.conversation = conversation
        self.messages = conversation?.messages ?? []
        self.documentId = documentId
    }
    
    /// Switches to a different conversation
    func switchToConversation(_ newConversation: ChatConversation?) {
        // Cancel any ongoing operations
        cancellationToken?.cancel()
        
        // Update the conversation and messages
        conversation = newConversation
        messages = newConversation?.messages ?? []
        
        // Reset state
        streamingAssistantMessage = nil
        isSending = false
        isProgressing = false
        newMessageText = ""
        messageReferences = [:]
    }
    
    /// Clears all messages in the current conversation and resets state
    func clearChat() {
        cancellationToken?.cancel()
        messages.removeAll()
        streamingAssistantMessage = nil
        isSending = false
        isProgressing = false
        newMessageText = ""
        messageReferences = [:]
    }

    func sendMessage() {
        let trimmed = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        newMessageText = ""
        isSending = true
        cancellationToken?.cancel()
        cancellationToken = CancellationToken()
        isProgressing = false
       

        Task {
            // Ensure conversation exists before creating any messages
            await createConversationIfNeeded()
            
            let userMessage = ChatMessage(
                id: UUID(),
                role: .user,
                content: trimmed,
                createdAt: Date(),
                updatedAt: Date(),
                conversation: conversation
            )

            await MainActor.run {
                self.messages.append(userMessage)
            }
            
            // Store the user message
            await storeMessage(userMessage)
            
            guard let chunks = await vectorStore.restoreEmbeddings(for: documentId) else {
                print("Failed to load document embeddings")
                return
            }
            let minimumScore = 0.25
            let topK = await chunkEmbedder.searchRelevantChunk(
                for: trimmed,
                chunks: chunks,
                limit: 3,
                minimumScore: minimumScore
            )
            let candidateChunks = topK.map { $0.documentChunk }
            
            // Build conversation history from the last 4 messages (minimal memory footprint)
            let conversationHistory = messages
                .dropLast()  // Exclude the current user message
                .suffix(4)   // Get only last 4 messages to minimize memory
                .map { msg -> String in
                    let role = msg.role == .user ? "Human" : "Assistant"
                    return "\(role): \(msg.content)"
                }
                .joined(separator: "\n\n")
            
            let prompt = promptContextGenerator.generateContext(
                for: trimmed,
                with: topK.map { $0.content }.joined(separator: "\n"),
                conversationHistory: conversationHistory
            )
            await handleCompletionStream(
                for: prompt,
                userMessage: userMessage,
                cancellationToken: cancellationToken!,
                referenceCandidates: candidateChunks
            )
        }
    }

    func stopStreaming() {
        cancellationToken?.cancel()
    }
    
    /// Generates a subject for the current conversation based on its messages
    func generateConversationSubject() async -> String? {
        guard !messages.isEmpty else { return nil }
        
        do {
            return try await subjectRepository.generateSubject(from: messages)
        } catch {
            print("Failed to generate conversation subject: \(error)")
            return nil
        }
    }
    
    /// Assigns a subject to the conversation if it's the first assistant reply
    private func assignSubjectIfFirstReply() async {
        guard let currentConversation = conversation else { return }
        
        // Check if this is the first assistant reply (should have exactly 2 messages: 1 user, 1 assistant)
        let assistantMessages = messages.filter { $0.role == .assistant }
        guard assistantMessages.count == 1 else { return }
        
        // Only generate subject if conversation doesn't already have one
        guard currentConversation.subject == nil || currentConversation.subject?.isEmpty == true else { return }
        
        do {
            // Generate subject based on current messages
            let subject = try await subjectRepository.generateSubject(from: messages)
            if !subject.isEmpty {
                // Update the conversation with the generated subject
                let updatedConversation = ChatConversation(
                    id: currentConversation.id,
                    messages: currentConversation.messages,
                    subject: subject,
                    createdAt: currentConversation.createdAt,
                    updatedAt: Date(),
                    document: currentConversation.document
                )
                
                // Update in repository
                let savedConversation = try await conversationRepository.update(entity: updatedConversation)
                
                // Update local state
                await MainActor.run {
                    self.conversation = savedConversation
                }
            }
        } catch {
            print("Failed to assign subject to conversation: \(error)")
        }
    }

    private func createConversationIfNeeded() async {
        guard conversation == nil else { return }
        
        do {
            // Get the document first
            guard let document = try await importedDocumentsRepository.read(id: documentId) else {
                print("Failed to find document with id: \(documentId)")
                return
            }
            
            let newConversation = ChatConversation(
                id: UUID(),
                messages: [],
                createdAt: Date(),
                updatedAt: Date(),
                document: document
            )
            
            let createdConversation = try await conversationRepository.create(entity: newConversation)
            await MainActor.run {
                self.conversation = createdConversation
            }
        } catch {
            print("Failed to create conversation: \(error)")
        }
    }
    
    private func storeMessage(_ message: ChatMessage) async {
        do {
            // Ensure the message has the current conversation reference
            guard let currentConversation = conversation else {
                print("Cannot store message: no conversation available")
                return
            }
            
            // Create a message with the proper conversation reference
            let messageWithConversation = ChatMessage(
                id: message.id,
                role: message.role,
                content: message.content,
                createdAt: message.createdAt,
                updatedAt: message.updatedAt,
                conversation: currentConversation
            )
            
            // Store the message
            try await conversationMessageRepository.create(entity: messageWithConversation)
            
            // Update the conversation's messages array
            var updatedConversation = currentConversation
            if !updatedConversation.messages.contains(where: { $0.id == messageWithConversation.id }) {
                updatedConversation.messages.append(messageWithConversation)
                await MainActor.run {
                    self.conversation = updatedConversation
                }
            }
        } catch {
            print("Failed to store message: \(error)")
        }
    }

    private func handleCompletionStream(
        for context: any ContextualPrompt,
        userMessage: ChatMessage,
        cancellationToken: CancellationToken,
        referenceCandidates: [DocumentChunk]
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
                            let assistantMessage = ChatMessage(
                                id: UUID(),
                                role: .assistant,
                                content: partial,
                                createdAt: Date(),
                                updatedAt: Date(),
                                conversation: self.conversation
                            )
                            self.streamingAssistantMessage = assistantMessage
                            self.messages.append(assistantMessage)
                        } else if let streaming = self.streamingAssistantMessage {
                            let updatedStreaming = ChatMessage(
                                id: streaming.id,
                                role: streaming.role,
                                content: streaming.content + partial,
                                createdAt: streaming.createdAt,
                                updatedAt: Date(),
                                conversation: self.conversation
                            )
                            self.streamingAssistantMessage = updatedStreaming
                            if let idx = self.conversation?.messages.lastIndex(where: {
                                $0.id == updatedStreaming.id
                            }) {
                                self.conversation?.messages[idx] = updatedStreaming
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
                            let finishedMessage = ChatMessage(
                                id: streaming.id,
                                role: streaming.role,
                                content: final,
                                createdAt: streaming.createdAt,
                                updatedAt: Date(),
                                conversation: self.conversation
                            )
                            if let idx = self.conversation?.messages.lastIndex(where: {
                                $0.id == streaming.id
                            }) {
                                self.conversation?.messages[idx] = finishedMessage
                            }
                            if let idx = self.messages.lastIndex(where: { $0.id == streaming.id }) {
                                self.messages[idx] = finishedMessage
                            }
                            
                            // Store the assistant message
                            await self.storeMessage(finishedMessage)

                            let resolved = self.referenceOutput.resolveReferences(
                                generatedAnswer: final,
                                candidateChunks: referenceCandidates
                            )
                            self.messageReferences[finishedMessage.id] = resolved
                        } else {
                            let assistantMessage = ChatMessage(
                                id: UUID(),
                                role: .assistant,
                                content: final,
                                createdAt: Date(),
                                updatedAt: Date(),
                                conversation: self.conversation
                            )
                            self.conversation?.messages.append(assistantMessage)
                            self.messages.append(assistantMessage)
                            
                            // Store the assistant message
                            await self.storeMessage(assistantMessage)

                            let resolved = self.referenceOutput.resolveReferences(
                                generatedAnswer: final,
                                candidateChunks: referenceCandidates
                            )
                            self.messageReferences[assistantMessage.id] = resolved
                        }
                        
                        // Generate and assign subject after first assistant reply
                        await self.assignSubjectIfFirstReply()
                        
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

