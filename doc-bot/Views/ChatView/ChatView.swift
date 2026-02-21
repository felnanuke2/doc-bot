import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showConversationDrawer = false
    @State private var selectedReference: DocumentChunk?
    
    private let documentId: UUID
    
    init(conversation: ChatConversation? = nil, documentId: UUID) {
        self.documentId = documentId
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation, documentId: documentId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageComponent(
                                message: message,
                                referenceChunks: viewModel.messageReferences[message.id] ?? [],
                                onReferenceTap: { chunk in
                                    selectedReference = chunk
                                }
                            )
                            .id(message.id)
                        }
                        
                        if viewModel.isProgressing || viewModel.isSending {
                            TypingIndicator()
                                .id("typing-indicator")
                        }
                    }
                    .padding(.vertical, 16)
                }
                .background(Color(.systemGroupedBackground))
                .onChange(of: viewModel.messages) { _ in
                    scrollToBottom(proxy: scrollProxy)
                }
                .onChange(of: viewModel.isProgressing) { _ in
                    scrollToBottom(proxy: scrollProxy)
                }
            }
            // Input Bar
            MessageInputBar(
                text: $viewModel.newMessageText,
                isSending: viewModel.isSending,
                isProgressing: viewModel.isProgressing,
                sendAction: { viewModel.sendMessage() },
                stopAction: { viewModel.stopStreaming() }
            )
        }
        .sheet(item: $selectedReference) { reference in
            PDFReferenceSheet(documentId: documentId, referenceChunk: reference)
        }
        .navigationTitle(documentTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button {
                        showConversationDrawer = true
                    } label: {
                        Image(systemName: "sidebar.left")
                    }
                    .accessibilityLabel(LocalizedString.accessibilitySidebar)
                    .foregroundColor(.primary)
                }
                
            }
        }
        .sheet(isPresented: $showConversationDrawer) {
            ConversationSideDrawer(
                isPresented: $showConversationDrawer,
                selectedConversation: .constant(viewModel.conversation),
                documentId: documentId
            ) { selectedConversation in
                viewModel.switchToConversation(selectedConversation)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var documentTitle: String {
        // First priority: Use conversation subject if available
        if let subject = viewModel.conversation?.subject, !subject.isEmpty {
            return subject
        }
        
        // Second priority: Use document name if available
        if let name = viewModel.conversation?.document.name, !name.isEmpty {
            return name
        }
        
        // Fallback: Default title
        return LocalizedString.navChat
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if viewModel.isProgressing {
                proxy.scrollTo("typing-indicator", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Preview Provider
#if DEBUG
struct ChatView_Previews: PreviewProvider {
    private static func createMockConversation() -> ChatConversation {
        let messages = [
            ChatMessage(
                id: UUID(),
                role: .assistant,
                content:
                    "Hello! I'm here to help you understand this document. What would you like to know?",
                createdAt: Date().addingTimeInterval(-300),
                updatedAt: Date().addingTimeInterval(-300),
                conversation: nil
            ),
            ChatMessage(
                id: UUID(),
                role: .user,
                content: "What are the key findings mentioned in section 3?",
                createdAt: Date().addingTimeInterval(-240),
                updatedAt: Date().addingTimeInterval(-240),
                conversation: nil
            ),
            ChatMessage(
                id: UUID(),
                role: .assistant,
                content:
                    "Section 3 presents several important findings:\n\n1. Climate change is accelerating coastal erosion rates\n2. Sea level rise is affecting infrastructure planning\n3. Adaptation strategies need immediate implementation\n\nWould you like me to elaborate on any of these points?",
                createdAt: Date().addingTimeInterval(-120),
                updatedAt: Date().addingTimeInterval(-120),
                conversation: nil
            ),
            ChatMessage(
                id: UUID(),
                role: .user,
                content: "Can you tell me more about the adaptation strategies?",
                createdAt: Date().addingTimeInterval(-60),
                updatedAt: Date().addingTimeInterval(-60),
                conversation: nil
            ),
        ]
        
        return ChatConversation(
            id: UUID(),
            messages: messages,
            createdAt: Date().addingTimeInterval(-400),
            updatedAt: Date(),
            document: ImportedDocument(
                id: UUID(),
                name: "Climate Impact Report 2024",
                createdAt: Date().addingTimeInterval(-86400),
                updatedAt: Date().addingTimeInterval(-86400)
            )
        )
    }
    
    static var previews: some View {
        let documentId = UUID()
        NavigationView {
            ChatView(conversation: createMockConversation(), documentId: documentId)
        }
        .preferredColorScheme(.light)
        
        NavigationView {
            ChatView(conversation: createMockConversation(), documentId: documentId)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
