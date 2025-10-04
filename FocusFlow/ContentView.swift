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
}

struct ContentView: View {
    @State var tab: ContentTab = .home
    
    var body: some View {
        TabView(selection: $tab) {
            Tab("Home", systemImage: "house", value: ContentTab.home) {
                HomeScreen()
            }
            Tab("Sessions", systemImage: "list.dash.header.rectangle", value: ContentTab.sessions) {
                Text("Sessions view")
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: FocusSession.self, configurations: .init(isStoredInMemoryOnly: true))
    ContentView()
        .modelContainer(container)
        .task {
            let context = container.mainContext
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759332600), duration: 3600, coins: 10))
            UserDefaults.standard.set(10, forKey: "coins")
        }
}
