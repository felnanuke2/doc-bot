//
//  ConcreteModelDownloaderRepository.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 21/07/25.
//

import Foundation

/// A concrete implementation of the `ModelDownloaderRepository`.

/// A concrete implementation of the `ModelDownloaderRepository` that handles concurrent downloads.
class ConcreteModelDownloaderRepository: NSObject, ModelDownloaderRepository, URLSessionDownloadDelegate {

    // A dictionary to store the continuation for each download task.
    // This allows handling multiple concurrent downloads safely.
    private var continuations = [URLSessionTask: AsyncStream<ModelDownloadResult>.Continuation]()
    private let accessQueue = DispatchQueue(label: "com.ModelDownloader.accessQueue")

    /// The URLSession to use for downloading, configured to use this class as its delegate.
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        // Using a nil delegateQueue means URLSession creates a serial operation queue
        // for all delegate callbacks, which simplifies synchronization.
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    /// Initiates a download for the model at the specified URL.
    func downloadModel(from url: URL) -> AsyncStream<ModelDownloadResult> {
        return AsyncStream { continuation in
            continuation.yield(.finished(.init(string: "abc.guff")!))
            continuation.finish()
        }
        
//        return AsyncStream { continuation in
//            let task = session.downloadTask(with: url)
//            // Safely store the continuation associated with the new task.
//            accessQueue.sync {
//                self.continuations[task] = continuation
//            }
//            task.resume()
//        }
    }

    /// Returns the local URL for a model if it has already been downloaded.
    func localModelURL(for url: URL) -> URL? {
        do {
            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let destinationURL = documentsURL.appendingPathComponent(url.lastPathComponent)

            // Check if the file exists at the destination path.
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                return destinationURL
            } else {
                return nil
            }
        } catch {
            // Using print for debugging, but consider a more robust logging strategy for production.
            print("Error getting documents directory: \(error)")
            return nil
        }
    }

    // MARK: - URLSessionDownloadDelegate

    /// Periodically informs the delegate about the download's progress.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        // Safely access the continuation for this task.
        accessQueue.sync {
            self.continuations[downloadTask]?.yield(.progressing(progress))
        }
    }

    /// Tells the delegate that a download task has finished downloading.
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let originalURL = downloadTask.originalRequest?.url else {
            let error = NSError(domain: "ModelDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not determine original download URL."])
            finish(task: downloadTask, with: .failure(error))
            return
        }

        do {
            // Determine the final destination for the downloaded file.
            let documentsURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let destinationURL = documentsURL.appendingPathComponent(originalURL.lastPathComponent)

            // If a file already exists at the destination, remove it first.
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }

            // Move the downloaded file from the temporary location to the documents directory.
            try FileManager.default.copyItem(at: location, to: destinationURL)

            // Finish the stream with the success result.
            finish(task: downloadTask, with: .finished(destinationURL))

        } catch {
            // Finish the stream with the failure result.
            finish(task: downloadTask, with: .failure(error))
        }
    }

    /// Tells the delegate that the task finished with an error.
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // This delegate method is called for both successful completions (error == nil)
        // and failures. We only act if there is an actual error, as the success case
        // is already handled by `didFinishDownloadingTo`.
        if let error = error {
            finish(task: task, with: .failure(error))
        }
    }

    /// A helper function to safely yield a final result, finish the stream, and clean up resources.
    private func finish(task: URLSessionTask, with result: ModelDownloadResult) {
        accessQueue.sync {
            if let continuation = self.continuations[task] {
                continuation.yield(result)
                continuation.finish()
                self.continuations[task] = nil
            }
        }
    }
}
