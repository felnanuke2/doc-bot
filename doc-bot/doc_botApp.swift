//
//  doc_botApp.swift
//  Doc Bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 20/07/25.
//

import SwiftUI

@main
struct doc_botApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
