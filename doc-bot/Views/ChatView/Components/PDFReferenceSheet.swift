import PDFKit
import SwiftUI

struct PDFReferenceSheet: View {
    let documentId: UUID
    let referenceChunk: DocumentChunk

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if let url = DocumentFileStore.storedDocumentURL(for: documentId) {
                    PDFReferenceView(documentURL: url, referenceChunk: referenceChunk)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Documento original nao encontrado.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Trecho de referencia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fechar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PDFReferenceView: UIViewRepresentable {
    let documentURL: URL
    let referenceChunk: DocumentChunk

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.backgroundColor = .systemBackground
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != documentURL {
            uiView.document = PDFDocument(url: documentURL)
        }

        guard let document = uiView.document,
              let page = document.page(at: referenceChunk.pageNumber)
        else { return }

        if let selection = selection(for: referenceChunk, in: page) {
            selection.color = .systemYellow
            uiView.setCurrentSelection(selection, animate: true)
            uiView.go(to: selection)
        } else {
            uiView.go(to: page)
        }
    }

    private func selection(for chunk: DocumentChunk, in page: PDFPage) -> PDFSelection? {
        if let range = chunk.boundingBox?.nsRange {
            return page.selection(for: range)
        }

        guard let pageText = page.string,
              let range = pageText.range(of: chunk.text)
        else {
            return nil
        }

        let nsRange = NSRange(range, in: pageText)
        return page.selection(for: nsRange)
    }
}
