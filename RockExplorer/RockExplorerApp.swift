//
//  RockExplorerApp.swift
//  RockExplorer
//
//  Created by Herb on 31/10/2568 BE.
//

import SwiftUI
import CoreData

@main
struct RockExplorerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
