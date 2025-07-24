import SwiftUI

struct ModelLoadingView: View {
    @ObservedObject var downloader: ModelDownloader
    var body: some View {
        VStack(spacing: 20) {
            switch downloader.state {
            case .notStarted:
                Text("Initializing...")
                ProgressView()
            case .downloading(let progress):
                Text("Downloading AI Model...")
                    .font(.headline)
                ProgressView(value: progress, total: 1.0) {
                    Text(String(format: "%.0f%%", progress * 100))
                }
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)
            case .failed(let error):
                Image(systemName: "xmark.octagon.fill")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text("Download Failed")
                    .font(.headline)
                Text(error.localizedDescription)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .padding()
            case .finished:
                Text("Download Complete!")
                    .font(.headline)
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
}
