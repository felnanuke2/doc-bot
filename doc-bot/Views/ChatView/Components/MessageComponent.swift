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
