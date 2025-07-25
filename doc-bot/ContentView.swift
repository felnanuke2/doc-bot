//
//  ContentView.swift
//  Doc Bot
//
//  Created by LUIZ FELIPE ALVES LIMA on 20/07/25.
//

import CoreData
import SwiftUI

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



#Preview {
    ContentView().environment(
        \.managedObjectContext, PersistenceController.preview.container.viewContext)
}
