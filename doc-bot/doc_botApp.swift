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
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - SwiftUI Views
struct RootView: View {
    // Create the ModelManager as a StateObject to keep it alive.
    @StateObject private var modelManager = ModelManager.shared

    var body: some View {
        // Pass the manager to the view hierarchy as an environment object.
        ContentView().environmentObject(modelManager)
    }
}
