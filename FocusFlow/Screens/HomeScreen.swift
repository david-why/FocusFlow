//
//  HomeScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/9/30.
//

import SwiftUI
import SwiftData

struct HomeScreen: View {
    var body: some View {
        NavigationStack {
//            ForEach(focusSessions) { session in
//                Text(session.startDate.formatted(date: .abbreviated, time: .shortened))
//            }
            progressView
            
            Text(lastSession?.startDate.formatted() ?? "No start date")
            .navigationTitle("FocusFlow")
        }
    }
    
    // MARK: - Timer state
    
    @State var timerRunning = false
    @State var timerSetting = TimeInterval(1800)
    @State var timerCurrent = TimeInterval(0) // increases to timerSetting as timer ticks
    
    // MARK: - Progress circle
    
    @ViewBuilder var progressView: some View {
        ZStack {
            CircularProgress(percentage: progressPercentage)
                .frame(width: 300)
            
            Text(progressText)
                .font(.system(size: 60))
                .monospacedDigit()
        }
        .foregroundStyle(Color.accentColor)
    }
    
    var progressPercentage: Double {
        timerRunning ? timerCurrent / timerSetting : 1.0
    }
    
    var progressText: String {
        let interval = timerRunning ? timerSetting - timerCurrent : timerSetting
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: interval) ?? "00:00"
    }
    
    // MARK: - Last session
    
    private static var lastSessionDescriptor: FetchDescriptor<FocusSession> {
        var descriptor = FetchDescriptor<FocusSession>(sortBy: [.init(\.startDate, order: .reverse)])
        descriptor.fetchLimit = 1
        return descriptor
    }
    
    @Query(lastSessionDescriptor) var lastSessionQuery: [FocusSession]
    
    var lastSession: FocusSession? {
        lastSessionQuery.first
    }
    
}

#Preview {
    let container = try! ModelContainer(for: FocusSession.self, configurations: .init(isStoredInMemoryOnly: true))
    HomeScreen()
        .modelContainer(container)
        .task {
            let context = container.mainContext
            try? await Task.sleep(for: .seconds(1))
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759332600), duration: 3600, multiplier: 1))
            try? await Task.sleep(for: .seconds(1))
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759327200), duration: 3600, multiplier: 1))
        }
}
