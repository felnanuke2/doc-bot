//
//  MessageInputBar.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 02/08/25.
//


import SwiftUI

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
                TextField(LocalizedString.chatPlaceholder, text: $text, axis: .vertical)
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
