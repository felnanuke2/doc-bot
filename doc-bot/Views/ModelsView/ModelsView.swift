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
    @AppStorage("modelTemperature") private var modelTemperature: Double = 0.7

    var body: some View {
        NavigationView {
            List {
                // Section for the currently active model
                Section(header: Text(LocalizedString.modelsActiveTitle)) {
                    if let activeModel = modelManager.activeModel {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(activeModel.name)
                                    .font(.headline)
                                Text(LocalizedString.modelsReady)
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
                            .accessibilityLabel(LocalizedString.accessibilityDelete)
                        }
                    } else {
                        Text(LocalizedString.modelsNoModel)
                            .foregroundColor(.secondary)
                    }
                }

                Section(
                    header: Text(LocalizedString.modelsTemperatureTitle),
                    footer: Text(LocalizedString.modelsTemperatureFooter)
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(LocalizedString.modelsTemperatureValue(modelTemperature))
                                .font(.subheadline)
                            Spacer()
                        }
                        Slider(value: $modelTemperature, in: 0.1...1.0, step: 0.1)
                            .accessibilityLabel(LocalizedString.modelsTemperatureTitle)
                    }
                    .padding(.vertical, 4)
                }
                
                // Section for available models to download
                Section(header: Text(LocalizedString.modelsAvailableTitle)) {
                    ForEach(modelManager.models) { model in
                        ModelRowView(model: model)
                    }
                }
            }
            .navigationTitle(LocalizedString.navModels)
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
                                Text(LocalizedString.modelsProgress(progress))
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
        .accessibilityLabel(LocalizedString.accessibilityDownload)
    }
}

// MARK: - Preview Provider
#Preview {
    RootView()
}
