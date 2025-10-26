//
//  SessionsListView.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/4.
//

import SwiftUI
import SwiftData

struct SessionsListView: View {
    @Query(sort: \FocusSession.startDate, order: .reverse) var sessions: [FocusSession]
    
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        List {
            ForEach(sessions) { session in
                NavigationLink(value: session) {
                    SessionSummary(session: session)
                }
            }
            .onDelete(perform: deleteIndices)
            if sessions.isEmpty {
                Text("No sessions yet. Start focusing!")
            }
        }
        .navigationTitle("Sessions")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: FocusSession.self) { session in
            SessionDetailView(session: session)
        }
    }
    
    func deleteIndices(_ indices: IndexSet) {
        let deletedSessions = indices.map { sessions[$0] }
        deletedSessions.forEach(modelContext.delete)
    }
}

struct SessionDetailView: View {
    let session: FocusSession
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        List {
            Section {
                LabeledContent("Time", value: session.startDate.formatted(date: .abbreviated, time: .shortened))
                
                LabeledContent("Duration", value: session.duration.formatted(.timeInterval.allowedUnits(.minute)))
                
                LabeledContent("Actual duration") {
                    Text(session.actualDuration.formatted(.timeInterval.allowedUnits([.minute, .second])))
                        .if(session.failed) { $0.foregroundStyle(.red) }
                }
                
                LabeledContent("Coins") {
                    Text("\(coinText) \(session.coins)")
                }
                
                if let task = session.task {
                    LabeledContent("Task") {
                        Text(task.name)
                    }
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
    SessionsListView()
}

#Preview("Session detail") {
    NavigationStack {
        SessionDetailView(session: FocusSession(startDate: .now, duration: 1800, coins: 30, actualDuration: 1800))
    }
}
