import PDFKit

class PdfKitDocumentContentExtractor: DocumentContentExtractor {
    func extractContent(from fileURL: URL) async -> [DocumentPageContent]? {
        extractPages(from: fileURL)
    }

    private func extractPages(from pdfURL: URL) -> [DocumentPageContent]? {
        guard let pdfDocument = PDFDocument(url: pdfURL) else { return nil }
        var pages: [DocumentPageContent] = []
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            if let pageText = page.string?.trimmingCharacters(in: .whitespacesAndNewlines), !pageText.isEmpty {
                pages.append(DocumentPageContent(pageNumber: pageIndex, text: pageText))
            }
        }
        return pages
    }
}
