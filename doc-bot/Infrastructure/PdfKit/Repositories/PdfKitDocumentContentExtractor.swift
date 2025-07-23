import PDFKit

class PdfKitDocumentContentExtractor: DocumentContentExtractor {
    func extractContent(from fileURL: URL) async -> String? {
       return self.extractText(from: fileURL)
        
    }

    func extractText(from pdfURL: URL) -> String? {
        guard let pdfDocument = PDFDocument(url: pdfURL) else { return nil }
        var fullText = ""
        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            if let pageText = page.string {
                fullText.append(pageText)
            }
        }
        return fullText
    }
}
