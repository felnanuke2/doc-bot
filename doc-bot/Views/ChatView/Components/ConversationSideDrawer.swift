import SwiftUI

struct ConversationSideDrawer: View {
    @StateObject private var viewModel: ConversationListViewModel
    @Binding var isPresented: Bool
    @Binding var selectedConversation: ChatConversation?
    let documentId: UUID
    let onConversationSelected: (ChatConversation?) -> Void
    
    init(
        isPresented: Binding<Bool>,
        selectedConversation: Binding<ChatConversation?>,
        documentId: UUID,
        onConversationSelected: @escaping (ChatConversation?) -> Void
    ) {
        self._isPresented = isPresented
        self._selectedConversation = selectedConversation
        self.documentId = documentId
        self.onConversationSelected = onConversationSelected
        self._viewModel = StateObject(wrappedValue: ConversationListViewModel(documentId: documentId))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text(LocalizedString.conversationsTitle)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(LocalizedString.conversationsNewChat) {
                        onConversationSelected(nil)
                        isPresented = false
                    }
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.separator)),
                    alignment: .bottom
                )
                
                // Content
                if viewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView(LocalizedString.conversationsLoading)
                        Spacer()
                    }
                } else if viewModel.conversations.isEmpty {
                    VStack {
                        Spacer()
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(LocalizedString.conversationsEmptyTitle)
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 16)
                        
                        Text(LocalizedString.conversationsEmptySubtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                            .padding(.top, 8)
                        
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(viewModel.conversations) { conversation in
                            ConversationListItem(
                                conversation: conversation,
                                isSelected: selectedConversation?.id == conversation.id,
                                onSelect: {
                                    onConversationSelected(conversation)
                                    isPresented = false
                                },
                                onDelete: {
                                    Task {
                                        await viewModel.deleteConversation(conversation)
                                        if selectedConversation?.id == conversation.id {
                                            onConversationSelected(nil)
                                        }
                                    }
                                }
                            )
                            .opacity(viewModel.isDeletingConversation == conversation.id ? 0.5 : 1.0)
                            .overlay(
                                viewModel.isDeletingConversation == conversation.id ?
                                ProgressView()
                                    .scaleEffect(0.8)
                                : nil
                            )
                            .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
                            .listRowBackground(Color.clear)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let conversation = viewModel.conversations[index]
                                Task {
                                    await viewModel.deleteConversation(conversation)
                                    if selectedConversation?.id == conversation.id {
                                        onConversationSelected(nil)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.clear)
                }
                
                if let error = viewModel.error {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.primary)
                            .font(.caption)
                        Spacer()
                        Button(LocalizedString.buttonDismiss) {
                            viewModel.clearError()
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.loadConversations()
        }
        .refreshable {
            await viewModel.loadConversations()
        }
    }
}

#if DEBUG
struct ConversationSideDrawer_Previews: PreviewProvider {
    static var previews: some View {
        ConversationSideDrawer(
            isPresented: .constant(true),
            selectedConversation: .constant(nil),
            documentId: UUID()
        ) { _ in }
        .preferredColorScheme(.light)
        
        ConversationSideDrawer(
            isPresented: .constant(true),
            selectedConversation: .constant(nil),
            documentId: UUID()
        ) { _ in }
        .preferredColorScheme(.dark)
    }
}
#endif
