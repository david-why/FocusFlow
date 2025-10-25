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
    case sessions
    case store
    case build
}

struct ContentView: View {
    @State var tab: ContentTab = .build  // TODO: Change this back to .home
    
    var body: some View {
        TabView(selection: $tab) {
            Tab("Home", systemImage: "house", value: ContentTab.home) {
                HomeScreen()
            }
            Tab("Sessions", systemImage: "list.dash.header.rectangle", value: ContentTab.sessions) {
                SessionsScreen()
            }
            Tab("Store", systemImage: "cart", value: ContentTab.store) {
                StoreScreen()
            }
            Tab("Build", systemImage: "wrench.and.screwdriver", value: ContentTab.build) {
                BuildScreen()
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: FocusSession.self, ReminderTask.self, BuildingItem.self, configurations: .init(isStoredInMemoryOnly: true))
    ContentView()
        .modelContainer(container)
        .environment(StoreService())
        .task {
            let context = container.mainContext
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759332600), duration: 3600, coins: 10, actualDuration: 3600))
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759339800), duration: 3600, coins: 30, actualDuration: 3600))
            UserDefaults.standard.set(1000, forKey: "coins")
            context.insert(BuildingItem(content: .image(name: "coin"), offsetX: 0, offsetY: 0, zIndex: 1))
        }
}
