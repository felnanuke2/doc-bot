//
//  Model.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 25/07/25.
//


import SwiftUI
import Combine



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
    private var modelToDownload: Model?

    private override init() {
        // Define the list of available models.
        self.models = [
            Model(name: "Qwen2-0.5B (Q4_K_M, 0.3 GiB)", url: "https://huggingface.co/QuantFactory/Qwen2-0.5B-GGUF/resolve/main/Qwen2-0.5B.Q4_K_M.gguf?download=true", filename: "Qwen2-0.5B.Q4_K_M.gguf"),
            Model(name: "TinyLlama-1.1B (Q4_0, 0.6 GiB)", url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-1T-OpenOrca-GGUF/resolve/main/tinyllama-1.1b-1t-openorca.Q4_0.gguf?download=true", filename: "tinyllama-1.1b-1t-openorca.Q4_0.gguf"),
            Model(name: "TinyLlama-1.1B Chat (Q8_0, 1.1 GiB)", url: "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q8_0.gguf?download=true", filename: "tinyllama-1.1b-chat-v1.0.Q8_0.gguf"),
            Model(name: "Phi-2.7B (Q4_0, 1.6 GiB)", url: "https://huggingface.co/ggml-org/models/resolve/main/phi-2/ggml-model-q4_0.gguf?download=true", filename: "phi-2-q4_0.gguf"),
            Model(name: "Mistral-7B-v0.1 (Q4_0, 3.8 GiB)", url: "https://huggingface.co/TheBloke/Mistral-7B-v0.1-GGUF/resolve/main/mistral-7b-v0.1.Q4_0.gguf?download=true", filename: "mistral-7b-v0.1.Q4_0.gguf"),
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

// MARK: - SwiftUI Views

struct RootView: View {
    // Create the ModelManager as a StateObject to keep it alive.
    @StateObject private var modelManager = ModelManager.shared

    var body: some View {
        // Pass the manager to the view hierarchy as an environment object.
        ContentView()
            .environmentObject(modelManager)
    }
}

struct ContentView: View {
    var body: some View {
        // The main UI is a TabView.
        TabView {
            ImportedDocumentsView()
                .tabItem {
                    Label("Import", systemImage: "doc.text.magnifyingglass")
                }
            
            ModelsView()
                .tabItem {
                    Label("Models", systemImage: "cpu")
                }
        }
    }
}

struct ModelsView: View {
    // Access the manager from the environment.
    @EnvironmentObject var modelManager: ModelManager

    var body: some View {
        NavigationView {
            List {
                // Section for the currently active model
                Section(header: Text("Active Model")) {
                    if let activeModel = modelManager.activeModel {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(activeModel.name)
                                    .font(.headline)
                                Text("Ready to use")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                modelManager.deleteActiveModel()
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        Text("No model downloaded. Select one from the list below.")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section for available models to download
                Section(header: Text("Available Models")) {
                    ForEach(modelManager.models) { model in
                        ModelRowView(model: model)
                    }
                }
            }
            .navigationTitle("Download Models")
        }
    }
}

struct ModelRowView: View {
    @EnvironmentObject var modelManager: ModelManager
    let model: Model

    var body: some View {
        HStack {
            Text(model.name)
            Spacer()
            
            // The view changes based on the model and download state.
            if model == modelManager.activeModel {
                // This model is the currently downloaded one.
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                // This model is not downloaded. Show a download button or progress.
                switch modelManager.downloadState {
                case .downloading(let progress):
                    // Check if THIS is the model being downloaded.
                    if model.url == modelManager.modelToDownload?.url {
                        VStack {
                            ProgressView(value: progress)
                            Text(String(format: "%.0f%%", progress * 100))
                                .font(.caption)
                        }
                        .padding(.horizontal)
                    } else {
                        // Another model is downloading, so this one's button is disabled.
                        downloadButton.disabled(true)
                    }
                case .notStarted, .finished, .failed:
                    // Show the download button if no download is active.
                    downloadButton
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var downloadButton: some View {
        Button {
            modelManager.download(model: model)
        } label: {
            Image(systemName: "icloud.and.arrow.down")
                .font(.title2)
        }
        .buttonStyle(.borderless) // Use borderless to make it look like a simple icon button.
    }
}


// Placeholder for your existing view.
struct ImportedDocumentsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "doc.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                Text("Document Import")
                    .font(.largeTitle)
                Text("Your document import UI goes here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Import")
        }
    }
}

// MARK: - Preview Provider
#Preview {
    RootView()
}
