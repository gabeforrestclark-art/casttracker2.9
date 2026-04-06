//
//  casttracker2_9App.swift
//  casttracker2.9
//
//  Created by gabe clark on 4/6/26.
//

import SwiftUI
import CoreData

@main
struct casttracker2_9App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
