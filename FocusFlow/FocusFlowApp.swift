//
//  FocusFlowApp.swift
//  FocusFlow
//
//  Created by David Wang on 2025/9/30.
//

import SwiftUI
import SwiftData

@main
struct FocusFlowApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(
                for: FocusSession.self, ReminderTask.self, BuildingItem.self,
                migrationPlan: MigrationPlan.self
            )
        } catch {
            container = try! ModelContainer(for: FocusSession.self, ReminderTask.self, BuildingItem.self)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(StoreService())
                .environment(SlackService())
        }
        .modelContainer(container)
    }
}
