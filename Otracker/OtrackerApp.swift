//
//  OtrackerApp.swift
//  Otracker
//
//  Created by Kev on 09/07/25.
//

import SwiftUI
import SwiftData

@main
struct OtrackerApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [
                    Transaction.self,
                    RecurringPayment.self,
                    Budget.self,
                    Category.self,
                    Subcategory.self,
                    SourceOfFund.self
        ])
    }
}
