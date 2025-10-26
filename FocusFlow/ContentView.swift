//
//  ContentView.swift
//  FocusFlow
//
//  Created by David Wang on 2025/9/30.
//

import SwiftUI
import SwiftData

enum ContentTab {
    case home
    case tasks
    case store
    case build
    case settings
}

struct ContentView: View {
    @State var tab: ContentTab = .home
    
    var body: some View {
        TabView(selection: $tab) {
            Tab("Home", systemImage: "house", value: ContentTab.home) {
                HomeScreen()
            }
            Tab("Tasks", systemImage: "list.bullet.clipboard", value: ContentTab.tasks) {
                TasksScreen()
            }
            Tab("Store", systemImage: "cart", value: ContentTab.store) {
                StoreScreen()
            }
            Tab("Build", systemImage: "wrench.and.screwdriver", value: ContentTab.build) {
                BuildScreen()
            }
            Tab("Settings", systemImage: "gear", value: ContentTab.settings) {
                SettingsScreen()
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: FocusSession.self, ReminderTask.self, BuildingItem.self, configurations: .init(isStoredInMemoryOnly: true))
    ContentView()
        .modelContainer(container)
        .environment(StoreService())
        .environment(SlackService())
        .task {
            let context = container.mainContext
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759332600), duration: 3600, coins: 10, actualDuration: 3600))
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759339800), duration: 3600, coins: 30, actualDuration: 3600))
            UserDefaults.standard.set(1000, forKey: "coins")
            context.insert(BuildingItem(content: .rect(color: .red), offsetX: 0, offsetY: 0, zIndex: 1, width: 100, height: 100, rotation: 0))
        }
}
