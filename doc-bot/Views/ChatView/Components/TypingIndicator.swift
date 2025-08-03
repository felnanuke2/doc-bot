//
//  TypingIndicator.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 02/08/25.
//


import SwiftUI

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

                Text(LocalizedString.chatTyping)
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
