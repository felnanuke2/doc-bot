import Foundation
import Combine

@MainActor
class ModelDownloader: NSObject, ObservableObject, URLSessionDownloadDelegate {
    enum DownloadState {
        case notStarted
        case downloading(progress: Double)
        case finished
        case failed(Error)
    }

    @Published var state: DownloadState = .notStarted
    static let shared = ModelDownloader()
    private var destinationURL: URL
    private let fileName = "ggml-model-q8_0.gguf"

    private override init() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.destinationURL = documentsURL.appendingPathComponent(fileName)
        super.init()
    }

    func downloadModelIfNeeded() {
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            print("Model already exists.")
            self.state = .finished
            return
        }
        print("Model not found. Starting download...")
        guard let modelURL = URL(string: "https://huggingface.co/QuantFactory/Qwen2-0.5B-GGUF/resolve/main/Qwen2-0.5B.Q4_K_M.gguf?download=true") else {
            self.state = .failed(URLError(.badURL))
            return
        }
        self.state = .downloading(progress: 0)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let downloadTask = session.downloadTask(with: modelURL)
        downloadTask.resume()
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.state = .downloading(progress: progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager.default.moveItem(at: location, to: destinationURL)
            print("Model downloaded and saved to \(destinationURL.path)")
            DispatchQueue.main.async {
                self.state = .finished
            }
        } catch {
            print("Error saving model: \(error)")
            DispatchQueue.main.async {
                self.state = .failed(error)
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Download error: \(error)")
            DispatchQueue.main.async {
                self.state = .failed(error)
            }
        }
    }
}
