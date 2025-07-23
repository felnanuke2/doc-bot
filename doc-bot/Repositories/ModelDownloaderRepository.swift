//
//  ModelDownloaderRepository.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 21/07/25.
//

import Foundation

/// A result type for model download operations.
enum ModelDownloadResult {
    case failure(Error)
    case waiting
    case progressing(Double)  // Progress as a value between 0.0 and 1.0
    case finished(URL)  // URL to the downloaded model file
}

/// A repository for downloading models.
protocol ModelDownloaderRepository {
    /// Downloads a model from a given URL asynchronously.
    /// - Parameter url: The URL to download the model from.
    /// - Returns: An async stream of download results.
    func downloadModel(from url: URL) -> AsyncStream<ModelDownloadResult>

    /// Checks if a model is already downloaded for a given URL.
    /// - Parameter url: The URL of the model.
    /// - Returns: The local file URL if downloaded, otherwise nil.
    func localModelURL(for url: URL) -> URL?
}
