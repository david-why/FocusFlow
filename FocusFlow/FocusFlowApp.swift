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
    
    @AppStorage("eventkit-tasks-synced") var syncingTasks = false
    @State var eventKitService = EventKitService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(StoreService())
                .environment(SlackService())
                .environment(eventKitService)
                .task {
                    if syncingTasks {
                        _ = await eventKitService.requestAccess()
                    }
                }
        }
        .modelContainer(container)
    }
}
