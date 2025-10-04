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
        Color.clear
            .frame(height: 20)
        Text("FocusFlow")
            .font(.largeTitle.bold())
            .foregroundStyle(Color.accentColor)
        Spacer()
        progressView
        Spacer()
        Text("Last session")
            .foregroundStyle(.secondary)
        VStack {
            HStack {
                Text("Thing")
                Spacer()
                Text("Other thing")
            }
            .padding()
            .background(Color.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        Spacer()
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
                .foregroundStyle(Color.accentColor)

            VStack {
                Text(progressText)
                    .font(.system(size: 60))
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
                    .padding(.bottom, -1) // layout bug?

                Text("\(Image(systemName: "alarm")) \(progressAlarmTime)")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .foregroundStyle(Color.secondary)
                    .background(Color.accentColor.opacity(0.2), in: Capsule())
            }
        }
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
    
    var progressAlarmTime: String {
        "22:01"
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
