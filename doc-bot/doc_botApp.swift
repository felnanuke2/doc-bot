//
//  doc_botApp.swift
//  Doc Bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 20/07/25.
//

import SwiftUI


import SwiftUI

@main
struct doc_botApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

struct RootView: View {
    @StateObject private var modelDownloader = ModelDownloader.shared

    var body: some View {
        Group {
            if case .finished = modelDownloader.state {
                ContentView()
            } else {
                ModelLoadingView(downloader: modelDownloader)
            }
        }
        .onAppear {
            modelDownloader.downloadModelIfNeeded()
        }
    }
}
