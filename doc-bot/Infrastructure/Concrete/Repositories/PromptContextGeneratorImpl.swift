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
        You are a helpful and precise AI assistant. Your task is to answer the user's question based *only* on the provided context.
        
        Follow these rules strictly:
        1.  Base your answer solely on the information given in the "CONTEXT" section. Do not use any external knowledge.
        2.  If the answer to the question cannot be found in the context, respond with "The information is not available in the provided context."
        3.  Answer the question directly and concisely.
        
        ---
        CONTEXT:
        \(context)
        
        QUESTION:
        \(prompt)
        """
       
        return GeneratedPrompt(content: output)
    }
}
