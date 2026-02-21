//
//  PromptContextGeneratorImpl.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 24/07/25.
//

struct GeneratedPrompt: ContextualPrompt {
    let content: String
    
   fileprivate init(content: String) {
        self.content = content
    }
}

final class PromptContextGeneratorImpl: PromptContextGenerator {
    func generateContext(for prompt: String, with context: String, conversationHistory: String) -> any ContextualPrompt {
        let historySection = conversationHistory.isEmpty ? "" : "Conversation:\n\(conversationHistory)\n\n"
        let trimmedContext = context.trimmingCharacters(in: .whitespacesAndNewlines)
        let contextSection = trimmedContext.isEmpty ? "" : "Context:\n\(trimmedContext)\n\n"
        let output = """
        \(historySection)\(contextSection)Question: \(prompt)
        
        Answer only based on context above. Keep answer short and direct:
"""
        return GeneratedPrompt(content: output)
    }
}
