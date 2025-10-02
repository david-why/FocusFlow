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
}

struct ContentView: View {
    @State var tab: ContentTab = .home
    
    var body: some View {
        TabView(selection: $tab) {
            Tab(value: ContentTab.home) {
                HomeScreen()
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FocusSession.self)
}
