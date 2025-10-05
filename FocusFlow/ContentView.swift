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
}

struct ContentView: View {
    @State var tab: ContentTab = .home
    
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
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: FocusSession.self, configurations: .init(isStoredInMemoryOnly: true))
    ContentView()
        .modelContainer(container)
        .environment(StoreService())
        .task {
            let context = container.mainContext
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759332600), duration: 3600, coins: 10, actualDuration: 3600))
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759339800), duration: 3600, coins: 30, actualDuration: 3600))
            UserDefaults.standard.set(50, forKey: "coins")
        }
}
