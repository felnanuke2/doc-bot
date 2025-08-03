import SwiftUI

struct ConversationListItem: View {
    let conversation: ChatConversation
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversationTitle)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(conversationPreview)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                
                Text(relativeDateString)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white.opacity(0.6) : .secondary)
            }
            
            Spacer()
            
            Menu {
                Button(LocalizedString.conversationDelete, role: .destructive) {
                    showingDeleteConfirmation = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    .rotationEffect(.degrees(90))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .alert(LocalizedString.conversationDeleteTitle, isPresented: $showingDeleteConfirmation) {
            Button(LocalizedString.conversationDelete, role: .destructive) {
                onDelete()
            }
            Button(LocalizedString.buttonCancel, role: .cancel) { }
        } message: {
            Text(LocalizedString.conversationDeleteMessage)
        }
    }
    
    private var conversationTitle: String {
        if let subject = conversation.subject {
            return subject
        }
        if let firstUserMessage = conversation.messages.first(where: { $0.role == .user }) {
            let title = firstUserMessage.content.prefix(30)
            return title.count < firstUserMessage.content.count ? "\(title)..." : String(title)
        }
        return LocalizedString.conversationNew
    }
    
    private var conversationPreview: String {
        if let lastMessage = conversation.messages.last {
            let trimmedContent = lastMessage.content.trimmingCharacters(in: .whitespacesAndNewlines)
            let preview = trimmedContent.prefix(60)
            return preview.count < trimmedContent.count ? "\(preview)..." : String(preview)
        }
        return LocalizedString.conversationNoMessages
    }
    
    private var relativeDateString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named
        return formatter.localizedString(for: conversation.updatedAt, relativeTo: Date())
    }
}

#if DEBUG
struct ConversationListItem_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ConversationListItem(
                conversation: ChatConversation(
                    id: UUID(),
                    messages: [
                        ChatMessage(
                            id: UUID(),
                            role: .user,
                            content: "What are the key findings in this document?",
                            createdAt: Date().addingTimeInterval(-300),
                            updatedAt: Date().addingTimeInterval(-300),
                            conversation: nil
                        ),
                        ChatMessage(
                            id: UUID(),
                            role: .assistant,
                            content: "The key findings include several important points about climate change and its impact on coastal regions...",
                            createdAt: Date().addingTimeInterval(-240),
                            updatedAt: Date().addingTimeInterval(-240),
                            conversation: nil
                        )
                    ],
                    createdAt: Date().addingTimeInterval(-400),
                    updatedAt: Date().addingTimeInterval(-240),
                    document: ImportedDocument(
                        id: UUID(),
                        name: "Climate Report",
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ),
                isSelected: false,
                onSelect: {},
                onDelete: {}
            )
            
            ConversationListItem(
                conversation: ChatConversation(
                    id: UUID(),
                    messages: [],
                    createdAt: Date(),
                    updatedAt: Date(),
                    document: ImportedDocument(
                        id: UUID(),
                        name: "Empty Report",
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                ),
                isSelected: true,
                onSelect: {},
                onDelete: {}
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
#endif
