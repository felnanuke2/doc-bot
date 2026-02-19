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
        let historySection = conversationHistory.isEmpty ? "" : "Previous conversation:\n\(conversationHistory)\n\n"
        let output = """
        You are a helpful assistant. Answer questions based ONLY on the provided context and conversation history.
        Be concise and factual. Stop immediately after answering the question.
        Do not add extra information, examples, or continue talking beyond what's necessary.
        If the answer is not in the context, say "I cannot find this information in the documents."
        
        \(historySection)Context: \(context)
        
        Human: \(prompt)
        
        Assistant:
"""
        return GeneratedPrompt(content: output)
    }
}
