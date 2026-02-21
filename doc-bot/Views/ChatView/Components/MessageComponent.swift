//
//  MessageView.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 02/08/25.
//


import SwiftUI

/// A professionally styled message bubble with improved typography and spacing
struct MessageComponent: View {
    let message: ChatMessage
    let referenceChunks: [DocumentChunk]
    let onReferenceTap: ((DocumentChunk) -> Void)?

    init(
        message: ChatMessage,
        referenceChunks: [DocumentChunk] = [],
        onReferenceTap: ((DocumentChunk) -> Void)? = nil
    ) {
        self.message = message
        self.referenceChunks = referenceChunks
        self.onReferenceTap = onReferenceTap
    }

    private var isUser: Bool {
        message.role == .user
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            if isUser {
                Spacer(minLength: 60)
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
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

                if !isUser && !referenceChunks.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reference:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let chunk = referenceChunks.first {
                            Text(referencePreview(for: chunk.text))
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Button {
                                onReferenceTap?(chunk)
                            } label: {
                                Text("View page \(chunk.pageNumber + 1)")
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color(.systemGray6))
                                    .foregroundColor(.primary)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }

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

    private func referencePreview(for text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let preview = trimmed.count > 160 ? String(trimmed.prefix(160)) + "..." : trimmed
        return preview.isEmpty ? "(no text)" : preview
    }
}
