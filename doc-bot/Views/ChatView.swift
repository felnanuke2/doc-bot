import SwiftUI

// MARK: - Message View
/// A professionally styled message bubble with improved typography and spacing
struct MessageView: View {
    let message: PdfMessage

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .lineLimit(nil)
                    .multilineTextAlignment(isUser ? .trailing : .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(backgroundForMessage)
                    .foregroundColor(foregroundForMessage)
                    // Use the new, softer message shape
                    .clipShape(
                        RoundedCorner(
                            radius: 20,
                            corners: isUser
                                ? [.topLeft, .topRight, .bottomLeft]
                                : [.topLeft, .topRight, .bottomRight]))

                Text(timeString(from: message.createdAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, isUser ? 16 : 4)
            }

            if !isUser {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
    }

    // Assistant message background is now more visible
    private var backgroundForMessage: Color {
        isUser ? Color.accentColor : Color(.systemGray5)
    }

    private var foregroundForMessage: Color {
        isUser ? .white : .primary
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Custom Rounded Corner Shape
/// A shape that allows rounding of specific corners, creating a gentler message bubble appearance.
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect, byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - Professional Typing Indicator
struct TypingIndicator: View {
    @StateObject private var animation = TypingAnimation()

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(animation.scales[index])
                            .animation(
                                Animation.easeInOut(duration: 0.6)
                                    .repeatForever()
                                    .delay(Double(index) * 0.2),
                                value: animation.scales[index]
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                // Use the new shape for the typing indicator too
                .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight, .bottomRight]))

                Text("Assistant is typing...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }

            Spacer(minLength: 60)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 2)
        .onAppear {
            animation.startAnimation()
        }
    }
}

// MARK: - Typing Animation Logic
final class TypingAnimation: ObservableObject {
    @Published var scales: [CGFloat] = [1.0, 1.0, 1.0]
    private var timer: Timer?

    func startAnimation() {
        // A more robust timer implementation for animation
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            let initialScales: [CGFloat] = [0.8, 0.8, 0.8]
            self.scales = initialScales

            DispatchQueue.main.async {
                withAnimation(Animation.easeInOut(duration: 0.3).delay(0)) { self.scales[0] = 1.2 }
                withAnimation(Animation.easeInOut(duration: 0.3).delay(0.15)) {
                    self.scales[1] = 1.2
                }
                withAnimation(Animation.easeInOut(duration: 0.3).delay(0.3)) {
                    self.scales[2] = 1.2
                }
            }
        }
        timer?.fire()
    }

    deinit {
        timer?.invalidate()
    }
}

// MARK: - Professional Input Bar
struct MessageInputBar: View {
    @Binding var text: String
    let isSending: Bool
    let isProgressing: Bool
    let sendAction: () -> Void
    let stopAction: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            // Changed alignment to .center
            HStack(alignment: .center, spacing: 12) {
                TextField("Ask about the document...", text: $text, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle())
                    .lineLimit(1...6)
                    .disabled(isSending || isProgressing)

                Button(action: isSending || isProgressing ? stopAction : sendAction) {
                    Image(
                        systemName: isSending || isProgressing
                            ? "stop.circle.fill" : "arrow.up.circle.fill"
                    )
                    .font(.title2)
                    .foregroundColor(
                        isSending || isProgressing
                            ? .red : (text.isEmpty ? .secondary : .accentColor))
                }
                .disabled(text.isEmpty && !isSending && !isProgressing)
                .animation(.easeInOut(duration: 0.2), value: isSending || isProgressing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(.systemGray4), lineWidth: 0.5)
            )
    }
}

// MARK: - Main Chat View
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @Environment(\.presentationMode) var presentationMode

    init(conversation: PdfConversation) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(conversation: conversation))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Messages List
            ScrollViewReader { scrollProxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(viewModel.messages) { message in
                            MessageView(message: message)
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
        .navigationTitle(documentTitle)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Clear Conversation", role: .destructive) {
                        viewModel.clearChat()
                    }

                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.primary)
                }
            }
        }
    }

    private var documentTitle: String {
        if let name = viewModel.conversation.document.name, !name.isEmpty {
            return name
        }
        return "Document Chat"
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
        private static func createMockConversation() -> PdfConversation {
            let messages = [
                PdfMessage(
                    id: UUID(),
                    role: .assistant,
                    content:
                        "Hello! I'm here to help you understand this document. What would you like to know?",
                    createdAt: Date().addingTimeInterval(-300),
                    updatedAt: Date().addingTimeInterval(-300)
                ),
                PdfMessage(
                    id: UUID(),
                    role: .user,
                    content: "What are the key findings mentioned in section 3?",
                    createdAt: Date().addingTimeInterval(-240),
                    updatedAt: Date().addingTimeInterval(-240)
                ),
                PdfMessage(
                    id: UUID(),
                    role: .assistant,
                    content:
                        "Section 3 presents several important findings:\n\n1. Climate change is accelerating coastal erosion rates\n2. Sea level rise is affecting infrastructure planning\n3. Adaptation strategies need immediate implementation\n\nWould you like me to elaborate on any of these points?",
                    createdAt: Date().addingTimeInterval(-120),
                    updatedAt: Date().addingTimeInterval(-120)
                ),
                PdfMessage(
                    id: UUID(),
                    role: .user,
                    content: "Can you tell me more about the adaptation strategies?",
                    createdAt: Date().addingTimeInterval(-60),
                    updatedAt: Date().addingTimeInterval(-60)
                ),
            ]

            return PdfConversation(
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
            NavigationView {
                ChatView(conversation: createMockConversation())
            }
            .preferredColorScheme(.light)

            NavigationView {
                ChatView(conversation: createMockConversation())
            }
            .preferredColorScheme(.dark)
        }
    }
#endif
