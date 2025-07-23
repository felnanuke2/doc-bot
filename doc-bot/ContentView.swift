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
        ImportedDocumentsView()
    }

}


#Preview {
    ContentView().environment(
        \.managedObjectContext, PersistenceController.preview.container.viewContext)
}
