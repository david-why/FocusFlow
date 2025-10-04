//
//  SessionsScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/4.
//

import SwiftUI
import SwiftData

struct SessionsScreen: View {
    @Query(sort: \FocusSession.startDate, order: .reverse) var sessions: [FocusSession]
    
    var body: some View {
        NavigationStack {
            List(sessions) { session in
                SessionSummary(session: session)
            }
            .navigationTitle("Sessions")
        }
    }
}

#Preview {
    SessionsScreen()
}
