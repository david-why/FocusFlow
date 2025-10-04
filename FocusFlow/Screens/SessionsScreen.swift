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
            List {
                ForEach(sessions) { session in
                    NavigationLink(value: session) {
                        SessionSummary(session: session)
                    }
                }
                if sessions.isEmpty {
                    Text("When you focus, \(coinText) flows!")
                }
            }
            .navigationTitle("Sessions")
            .navigationDestination(for: FocusSession.self) { session in
                SessionDetailView(session: session)
            }
        }
    }
    
    // MARK: - Detail view
}

struct SessionDetailView: View {
    let session: FocusSession
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        List {
            Section {
                LabeledContent("Time", value: session.startDate.formatted(date: .abbreviated, time: .shortened))
                
                LabeledContent("Duration", value: session.duration.formatted(.timeInterval))
                
                LabeledContent("Coins") {
                    Text("\(coinText) \(session.coins)")
                }
            }
            
            Section {
                Button("Delete this session", role: .destructive) {
                    modelContext.delete(session)
                    dismiss()
                }
            }
        }
        .navigationTitle(session.startDate.formatted(date: .abbreviated, time: .omitted))
    }
}

#Preview {
    SessionsScreen()
}

#Preview("Session detail") {
    NavigationStack {
        SessionDetailView(session: FocusSession(startDate: .now, duration: 1800, coins: 30, task: nil))
    }
}
