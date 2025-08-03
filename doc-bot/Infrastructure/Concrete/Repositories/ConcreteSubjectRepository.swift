import Foundation
import NaturalLanguage

/// Concrete implementation of SubjectRepository that uses NaturalLanguage framework
/// to analyze messages and generate conversation subjects
class ConcreteSubjectRepository: SubjectRepository {
    
    func generateSubject(from messages: [ChatMessage]) async throws -> String {
        guard !messages.isEmpty else {
            return "Empty Conversation"
        }
        
        // Get the first few user messages to understand the conversation topic
        let userMessages = messages
            .filter { $0.role == .user }
            .prefix(3)
            .map { $0.content }
        
        guard !userMessages.isEmpty else {
            return "Assistant Conversation"
        }
        
        // Combine the first few messages
        let combinedText = userMessages.joined(separator: " ")
        
        // Use a simple approach to extract key topics
        return await extractSubjectFromText(combinedText)
    }
    
    private func extractSubjectFromText(_ text: String) async -> String {
        // Remove extra whitespace and limit length
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // If text is short enough, use it directly (with some cleanup)
        if cleanText.count <= 50 {
            return cleanText.isEmpty ? "New Conversation" : cleanText
        }
        
        // For longer text, try to extract key phrases using NaturalLanguage
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = cleanText
        
        var keyWords: [String] = []
        
        // Extract named entities and important words
        tagger.enumerateTags(in: cleanText.startIndex..<cleanText.endIndex, 
                           unit: .word, 
                           scheme: .nameType, 
                           options: [.omitWhitespace, .omitPunctuation]) { tag, tokenRange in
            let word = String(cleanText[tokenRange])
            
            // Include named entities and longer significant words
            if tag != nil || word.count >= 4 {
                keyWords.append(word)
            }
            
            // Limit to first 5 key words
            return keyWords.count < 5
        }
        
        // If we found key words, use them
        if !keyWords.isEmpty {
            let subject = keyWords.prefix(3).joined(separator: " ")
            return subject.count > 50 ? String(subject.prefix(47)) + "..." : subject
        }
        
        // Fallback: use first few words of the text
        let words = cleanText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(5)
        
        let fallbackSubject = words.joined(separator: " ")
        return fallbackSubject.count > 50 ? String(fallbackSubject.prefix(47)) + "..." : fallbackSubject
    }
}
