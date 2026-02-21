//
//  ModelManager.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 25/07/25.
//
import Foundation

// MARK: - Model Manager
// An ObservableObject to manage model state, downloads, and persistence.
@MainActor
class ModelManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    
    // Enum to represent the various states of a download.
    enum DownloadState {
        case notStarted
        case downloading(progress: Double)
        case finished
        case failed(Error)
    }

    // Published properties to drive UI updates.
    @Published var models: [Model]
    @Published var downloadState: DownloadState = .notStarted
    @Published var activeModel: Model?

    // Singleton pattern for easy access throughout the app.
    static let shared = ModelManager()

    // The single destination URL for any downloaded model.
    private let destinationURL: URL
    private let standardModelFileName = "ggml-model.gguf"
    private let userDefaultsKey = "activeModelURL"

    // The currently active download task.
    private var downloadTask: URLSessionDownloadTask?
    var modelToDownload: Model?

    private override init() {
        // Define the list of available models - optimized for edge AI on mobile devices.
        // Models are sorted by size (smallest to largest) for better mobile performance.
        self.models = [
            // Ultra-lightweight models (< 500 MB) - Optimized for mobile devices
            Model(name: "Qwen2-0.5B Instruct (Q2_K, 0.32 GiB)", url: "https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q2_k.gguf?download=true", filename: "qwen2-0_5b-instruct-q2_k.gguf"),
            Model(name: "Qwen2-0.5B Instruct (Q4_K_M, 0.38 GiB) ⭐", url: "https://huggingface.co/Qwen/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q4_k_m.gguf?download=true", filename: "qwen2-0_5b-instruct-q4_k_m.gguf"),
            Model(name: "Qwen3-0.6B Instruct (Q8_0, 0.48 GiB)", url: "https://huggingface.co/Qwen/Qwen3-0.6B-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf?download=true", filename: "Qwen3-0.6B-Q8_0.gguf"),
        ]
        
        // Set up the file path for the downloaded model.
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.destinationURL = documentsURL.appendingPathComponent(standardModelFileName)
        
        super.init()

        // Load the active model information from UserDefaults.
        loadActiveModel()
    }

    // MARK: - Public Interface

    /// Starts downloading a selected model.
    func download(model: Model) {
        // Prevent starting a new download if one is already in progress.
        guard downloadTask == nil else {
            print("Another download is already in progress.")
            return
        }
        
        print("Starting download for \(model.name)...")
        self.modelToDownload = model
        
        guard let url = URL(string: model.url) else {
            self.downloadState = .failed(URLError(.badURL))
            return
        }
        
        self.downloadState = .downloading(progress: 0)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        downloadTask = session.downloadTask(with: url)
        downloadTask?.resume()
    }
    
    /// Deletes the currently downloaded model file.
    func deleteActiveModel() {
        guard activeModel != nil else { return }
        
        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
                print("Successfully deleted model file.")
            }
            // Clear from UserDefaults and update state
            UserDefaults.standard.removeObject(forKey: userDefaultsKey)
            self.activeModel = nil
            self.downloadState = .notStarted
        } catch {
            print("Error deleting model file: \(error)")
            self.downloadState = .failed(error)
        }
    }

    // MARK: - Persistence
    
    /// Loads the active model from UserDefaults and checks if the file exists.
    private func loadActiveModel() {
        let fileManager = FileManager.default
        
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decodedModel = try? JSONDecoder().decode(Model.self, from: data) {
            
            // If the file exists at the destination, the model is active.
            if fileManager.fileExists(atPath: destinationURL.path) {
                self.activeModel = decodedModel
                self.downloadState = .finished
                print("Loaded active model: \(decodedModel.name)")
            } else {
                // If the file is missing, clear the stale UserDefaults entry.
                print("Found model reference but file is missing. Clearing.")
                UserDefaults.standard.removeObject(forKey: userDefaultsKey)
                self.activeModel = nil
                self.downloadState = .notStarted
            }
        }
    }

    /// Saves the successfully downloaded model's info to UserDefaults.
    private func saveActiveModel(_ model: Model) {
        if let data = try? JSONEncoder().encode(model) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            self.activeModel = model
            print("Saved \(model.name) as active model.")
        }
    }

    // MARK: - URLSessionDownloadDelegate Methods

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        // Update the UI on the main thread.
        DispatchQueue.main.async {
            self.downloadState = .downloading(progress: progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let fileManager = FileManager.default
        
        // Remove the old model file if it exists, to be replaced.
        if fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.removeItem(at: destinationURL)
                print("Removed old model file.")
            } catch {
                print("Could not remove old model file: \(error)")
                // Proceed anyway, as moveItem will attempt to overwrite.
            }
        }
        
        do {
            // Move the temporary downloaded file to the permanent location.
            try fileManager.moveItem(at: location, to: destinationURL)
            print("Model saved to \(destinationURL.path)")
            
            DispatchQueue.main.async {
                if let downloadedModel = self.modelToDownload {
                    self.saveActiveModel(downloadedModel)
                }
                self.downloadState = .finished
                self.cleanupDownloadTask()
            }
        } catch {
            print("Error saving model: \(error)")
            DispatchQueue.main.async {
                self.downloadState = .failed(error)
                self.cleanupDownloadTask()
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // This delegate method is called for any error, including cancellation.
        // We only care about actual network/server errors.
        if let error = error {
            // Ignore cancellation errors which are expected if the user stops the download.
            let nsError = error as NSError
            if !(nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled) {
                print("Download error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.downloadState = .failed(error)
                    self.cleanupDownloadTask()
                }
            }
        }
    }
    
    private func cleanupDownloadTask() {
        self.downloadTask = nil
        self.modelToDownload = nil
    }
}
