import SwiftUI

// Models remain the same...

/// A view that renders a single message bubble, styled based on the sender's role.
struct MessageView: View {
    let message: PdfMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }

            Text(message.content)
                .padding(12)
                .background(message.role == .user ? .blue : .gray.opacity(0.2))
                .foregroundColor(message.role == .user ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if message.role == .assistant {
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}


/// The main chat interface view. It is now initialized with a conversation object.
struct ChatView: View {
    @State private var conversation: PdfConversation
    @State private var newMessageText: String = ""
    
    // The view is now initialized directly with the conversation it needs to display.
    // This makes the view more reusable and independent of how data is fetched.
    init(conversation: PdfConversation) {
        self._conversation = State(initialValue: conversation)
    }

    var body: some View {
        VStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(conversation.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                    }
                }
                .onChange(of: conversation.messages.count) {
                    if let lastMessage = conversation.messages.last {
                        withAnimation {
                            scrollViewProxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            HStack {
                TextField("Ask about the document...", text: $newMessageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...5)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title)
                }
                .disabled(newMessageText.isEmpty)
            }
            .padding()
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sendMessage() {
        guard !newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let userMessage = PdfMessage(
            id: UUID(),
            role: .user,
            content: newMessageText,
            createdAt: Date(),
            updatedAt: Date()
        )
        conversation.messages.append(userMessage)
        let sentText = newMessageText
        newMessageText = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let assistantReply = PdfMessage(
                id: UUID(),
                role: .assistant,
                content: "This is a simulated response to: \"\(sentText)\"",
                createdAt: Date(),
                updatedAt: Date()
            )
            conversation.messages.append(assistantReply)
        }
    }
}

// A preview provider to make the ChatView easy to develop and test in Xcode.
struct ChatView_Previews: PreviewProvider {
    // The mock data generation is now private to the preview provider.
    private static func loadMockConversation() -> PdfConversation {
        return PdfConversation(
            id: UUID(),
            messages: [
                PdfMessage(id: UUID(), role: .assistant, content: "Hello! How can I help you with this document?", createdAt: Date().addingTimeInterval(-120), updatedAt: Date().addingTimeInterval(-120)),
                PdfMessage(id: UUID(), role: .user, content: "What is the main topic of section 3?", createdAt: Date().addingTimeInterval(-60), updatedAt: Date().addingTimeInterval(-60)),
                PdfMessage(id: UUID(), role: .assistant, content: "Section 3 primarily discusses the impact of climate change on coastal regions.", createdAt: Date(), updatedAt: Date())
            ],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    static var previews: some View {
        NavigationView {
            // We create the mock data here and pass it to the view's initializer.
            ChatView(conversation: loadMockConversation())
        }
    }
}
