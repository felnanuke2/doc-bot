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
    func generateContext(for prompt: String, with context: String) -> any ContextualPrompt {
        let output = """
        Context: \(context)
        
        Human: \(prompt)
        
        Assistant: Based on the given context, I will provide a concise and accurate answer to the question.
        """
        return GeneratedPrompt(content: output)
    }
}
