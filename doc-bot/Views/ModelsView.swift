//
//  Model.swift
//  doc-bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 25/07/25.
//


import SwiftUI
import Combine


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
                HStack {
                    Spacer(minLength: 0)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                .frame(width: 48, alignment: .trailing)
            } else {
                // This model is not downloaded. Show a download button or progress.
                switch modelManager.downloadState {
                case .downloading(let progress):
                    // Check if THIS is the model being downloaded.
                    if model.url == modelManager.modelToDownload?.url {
                        HStack {
                            Spacer(minLength: 0)
                            VStack {
                                ProgressView(value: progress)
                                    .progressViewStyle(.circular)
                                    .frame(width: 28, height: 28)
                                Text(String(format: "%.0f%%", progress * 100))
                                    .font(.caption)
                            }
                        }
                        .frame(width: 48, alignment: .trailing)
                        .padding(.horizontal, 0)
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

// MARK: - Preview Provider
#Preview {
    RootView()
}
