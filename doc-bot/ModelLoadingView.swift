import SwiftUI

struct ModelLoadingView: View {
    @ObservedObject var downloader: ModelDownloader
    var body: some View {
        VStack(spacing: 20) {
            switch downloader.state {
            case .notStarted:
                Text(LocalizedString.modelInitializing)
                ProgressView()
            case .downloading(let progress):
                Text(LocalizedString.modelDownloading)
                    .font(.headline)
                ProgressView(value: progress, total: 1.0) {
                    Text(LocalizedString.modelsProgress(progress))
                }
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
            case .failed(let error):
                Image(systemName: "xmark.octagon.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text(LocalizedString.modelDownloadFailed)
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            case .finished:
                Text(LocalizedString.modelDownloadComplete)
                    .font(.headline)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}
