import SwiftUI

struct DocumentRowView: View {
    // MARK: - Properties
    
    let document: ImportedDocument
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 12) {
            documentIcon
            documentInfo
            Spacer()
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle()   )
    }
    
    // MARK: - View Components
    
    private var documentIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemRed))
                .frame(width: 40, height: 40)
            
            Image(systemName: "doc.text.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
        }
    }
    
    private var documentInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(document.name ?? LocalizedString.documentsUntitled)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)
            
            Text(conversationCountText)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Computed Properties
    
    private var conversationCountText: String {
        let count = document.conversations?.count ?? 0
        return LocalizedString.conversationsCount(count)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 0) {
        DocumentRowView(
            document: ImportedDocument(
                id: UUID(),
                name: "iOS Development Guide.pdf",
                conversations: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        )
        
        Divider()
        
        DocumentRowView(
            document: ImportedDocument(
                id: UUID(),
                name: "SwiftUI Best Practices and Design Patterns.pdf",
                conversations: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        )
        
        Divider()
        
        DocumentRowView(
            document: ImportedDocument(
                id: UUID(),
                name: nil, // Test untitled document
                conversations: [],
                createdAt: Date(),
                updatedAt: Date()
            )
        )
    }
    .background(Color(.systemGroupedBackground))
}
