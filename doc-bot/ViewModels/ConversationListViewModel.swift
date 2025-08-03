import Foundation
import Factory

@MainActor
class ConversationListViewModel: ObservableObject {
    @Injected(\.conversationRepository) private var conversationRepository: any ConversationRepository
    
    @Published var conversations: [ChatConversation] = []
    @Published var isLoading: Bool = false
    @Published var isDeletingConversation: UUID?
    @Published var error: String?
    
    private let documentId: UUID
    
    init(documentId: UUID) {
        self.documentId = documentId
    }
    
    func loadConversations() async {
        isLoading = true
        error = nil
        
        do {
            let fetchedConversations = try await conversationRepository.conversationsForDocument(documentId: documentId)
            await MainActor.run {
                self.conversations = fetchedConversations
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to load conversations: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    func deleteConversation(_ conversation: ChatConversation) async {
        await MainActor.run {
            self.isDeletingConversation = conversation.id
            self.error = nil
        }
        
        do {
            try await conversationRepository.delete(id: conversation.id)
            await MainActor.run {
                self.conversations.removeAll { $0.id == conversation.id }
                self.isDeletingConversation = nil
            }
        } catch {
            await MainActor.run {
                self.error = "Failed to delete conversation: \(error.localizedDescription)"
                self.isDeletingConversation = nil
            }
        }
    }
    
    func getConversationPreview(_ conversation: ChatConversation) -> String {
        if let firstUserMessage = conversation.messages.first(where: { $0.role == .user }) {
            let preview = firstUserMessage.content.prefix(50)
            return preview.count < firstUserMessage.content.count ? "\(preview)..." : String(preview)
        }
        return "New Conversation"
    }
    
    func clearError() {
        error = nil
    }
}
