//
//  HomeScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/9/30.
//

import SwiftUI
import SwiftData
import Combine

struct HomeScreen: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.scenePhase) var scenePhase
    @Environment(StoreService.self) var storeService
    @Environment(SlackService.self) var slackService
    
    @Query var incompleteTasks: [ReminderTask]
    
    var body: some View {
        NavigationStack {
            content
                .navigationDestination(for: SessionsScreenDestination.self) { _ in
                    SessionsListView()
                }
        }
        .onReceive(timer, perform: onTimerTick)
        .alert("You did it!", isPresented: $isPresentingCongrats) {} message: {
            Text("You focused for \(timerSetting.formatted(.timeInterval.allowedUnits(.minute).unitsStyle(.full)))! Enjoy your reward of \(lastCoinGain) coins!")
        }
        .onChange(of: scenePhase) { old, new in
            print("Scene phase changed to \(new)")
            if new == .background && timerRunning {
                print("Failed due to scene changed to .background")
                userDidFail()
            }
            if new == .active && isFailing {
                penalizeUser()
            }
        }
        .alert("You failed...", isPresented: $isPresentingFailed) {} message: {
            Text("You have left this page... You lost 50% of your coins.")
        }
        .onDisappear {
            print("onDisappear: \(timerRunning) \(scenePhase)")
            if timerRunning && scenePhase == .active {
                print("Failed due to timer running on onDisappear")
                userDidFail()
            }
        }
        .onAppear {
            if isFailing {
                penalizeUser()
            }
        }
        .onChange(of: timerRunning) { old, new in
            print("timerRunning changed to \(new)")
            UIApplication.shared.isIdleTimerDisabled = new
        }
        .alert("Warning!", isPresented: $isPresentingHint) {
            Button("OK") {
                hintShown = true
                startTimer()
            }
        } message: {
            Text("Once you press OK, you must not leave this page (including closing this app AND switching to another tab)! Otherwise, your hard-earned coins are at risk...")
        }
        .alert("You were redeemed...", isPresented: $isPresentingSaved, presenting: savedPassName) { _ in } message: { name in
            Text("You were distracted, but saved by a \(name). Don't let this happen again...")
        }
    }
    
    @ViewBuilder var content: some View {
        Spacer()
        Text("Focus!")
            .font(.largeTitle.bold())
            .padding(.bottom, 4)
        Text("\(coinText) \(coins)")
            .onTapGesture(count: 10) {
                coins = 500
            }
        Spacer()
        progressView
        buttonsView
            .padding(.top, 20)
        Spacer()
        Text("Last session")
            .foregroundStyle(.secondary)
        VStack {
            NavigationLink(value: SessionsScreenDestination.value) {
                lastSessionView
            }
            .tint(.primary)
            .navigationLinkIndicatorVisibility(lastSession == nil ? .hidden : .visible)
            .padding()
            .background(.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        Spacer()
    }
    
    @AppStorage("home_hint_shown") var hintShown = false
    @AppStorage("coins") var coins = 0
    
    @State var lastCoinGain = 0
    @State var isPresentingCongrats = false
    @State var isPresentingFailed = false
    @State var isPresentingHint = false
    @State var isPresentingSaved = false
    @State var savedPassName: LocalizedStringResource? = nil
    
    // MARK: - Session state
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State var now = Date.now
    
    @AppStorage("working_task_id") var workingTaskID: String?
    @AppStorage("is_current_failing") var isFailing = false
    @AppStorage("current_fail_time") var failTime = Date.distantPast
    @AppStorage("current_fail_start_date") var failStartDate = Date.distantPast
    
    @AppStorage("hasFailedBuild") var hasFailedBuild = false

    // MARK: - Timer state
    
    @AppStorage("timer_setting") var timerSetting = TimeInterval(1800)
    
    @AppStorage("timer_distracted_time") var timerDistractedTime = TimeInterval(0)
    @AppStorage("timer_is_started") var timerIsStartedValue = false
    @AppStorage("timer_start_date") var timerStartDateValue = Date.now
    
    var timerStartDate: Date? {
        get {
            timerIsStartedValue ? timerStartDateValue : nil
        }
        nonmutating set {
            if let date = newValue {
                timerIsStartedValue = true
                timerStartDateValue = date
            } else {
                timerIsStartedValue = false
            }
        }
    }
    
    var timerRunning: Bool {
        timerStartDate != nil
    }
    
    var timerEndDate: Date? {
        timerStartDate?.addingTimeInterval(timerSetting)
    }
    
    var timerCurrent: TimeInterval {
        if let timerStartDate {
            return now.timeIntervalSince(timerStartDate)
        } else {
            return 0
        }
    }
    
    // MARK: - Progress circle
    
    @ScaledMetric var timerFontSize = 60

    @ViewBuilder var progressView: some View {
        ZStack {
            CircularProgress(percentage: progressPercentage)
                .frame(width: 300)
                .foregroundStyle(Color.accentColor)

            VStack {
                Text(progressText)
                    .font(.system(size: timerFontSize))
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
                    .padding(.bottom, -1) // layout bug?

                HStack {
                    Text("\(Image(systemName: "flag.pattern.checkered")) \(progressAlarmTime)")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .foregroundStyle(.secondary)
                        .background(Color.accentColor.opacity(0.2), in: Capsule())
                    
                    Menu {
                        Picker("label", selection: $workingTaskID) {
                            Text("(None)").tag(Optional<String>.none)
                            ForEach(incompleteTasks) { task in
                                Text(task.name).tag(task.id)
                            }
                        }
                    } label: {
                        Text(Image(systemName: workingTask == nil ? "plus.circle" : "checkmark.circle.fill"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color.accentColor.opacity(0.2), in: Capsule())
                    }
                    .disabled(timerStartDate != nil)
                }
            }
        }
    }
    
    var progressPercentage: Double {
        timerRunning ? 1 - timerCurrent / timerSetting : 1.0
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
        ((timerStartDate ?? now).addingTimeInterval(timerSetting)).formatted(date: .omitted, time: .shortened)
    }
    
    // MARK: - Action buttons
    
    @ScaledMetric(relativeTo: .headline) var buttonSize = 40
    
    @ViewBuilder var buttonsView: some View {
        HStack {
            actionButton(systemImage: "minus", action: decreaseTimer)
                .buttonRepeatBehavior(.enabled)
            Spacer()
            actionButton(systemImage: timerRunning ? "stop" : "play", style: .borderedProminent, action: startTimer)
            Spacer()
            actionButton(systemImage: "plus", action: increaseTimer)
                .buttonRepeatBehavior(.enabled)
        }
        .frame(maxWidth: 300)
        .disabled(timerRunning)
    }
    
    func actionButton(systemImage: String, style: some PrimitiveButtonStyle = .bordered, action: @escaping @MainActor () -> Void) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.headline)
                .frame(width: buttonSize, height: buttonSize)
        }
        .buttonStyle(style)
        .clipShape(Circle())
    }
    
    // MARK: - Last session
    
    @ViewBuilder var lastSessionView: some View {
        if let lastSession {
            SessionSummary(session: lastSession)
        } else {
            HStack {
                Spacer()
                Text("When you focus, \(coinText) flows!")
                Spacer()
            }
        }
    }
    
    private static var lastSessionDescriptor: FetchDescriptor<FocusSession> {
        var descriptor = FetchDescriptor<FocusSession>(sortBy: [.init(\.startDate, order: .reverse)])
        descriptor.fetchLimit = 1
        return descriptor
    }
    
    @Query(lastSessionDescriptor) var lastSessionQuery: [FocusSession]
    
    var lastSession: FocusSession? {
        lastSessionQuery.first
    }
    
    // MARK: - Events
    
    /// Called each second.
    func onTimerTick(date: Date) {
        now = date
        if let timerEndDate, now > timerEndDate {
            timerDidExpire()
        }
    }
    
    /// The timer finished by itself.
    func timerDidExpire() {
        guard let timerStartDate else { return }
        let coinsWon = calculateCoins()
        let actualTime = timerSetting - timerDistractedTime
        let session = FocusSession(startDate: timerStartDate, duration: timerSetting, coins: coinsWon, actualDuration: actualTime, task: workingTask)
        modelContext.insert(session) // TODO: Extract to its own function
        coins += coinsWon
        self.timerStartDate = nil
        lastCoinGain = coinsWon
        isPresentingCongrats = true
        workingTaskID = nil
        Task {
            try? await slackService.postMessage("FocusFlow: Completed focus session!\n* Actual focus time: \(actualTime.formatted(.timeInterval))\n* Coins earned: \(coinsWon)")
        }
        Task {
            try? await slackService.clearStatus()
        }
    }
    
    /// The user left the app.
    func userDidFail() {
        guard !isFailing, let timerStartDate else { return }
        isFailing = true
        failTime = .now
        failStartDate = timerStartDate
        self.timerStartDate = nil
        UserDefaults.standard.synchronize()
    }
    
    /// The user has returned after failing. (How dare they?)
    func penalizeUser() {
        guard isFailing else { return }
        isFailing = false
        let distractionEndDate = min(Date.now, failStartDate + timerSetting)
        // Use the passes
        if distractionEndDate.timeIntervalSince(failTime) <= 60 {
            let passes = storeService.items(of: "break-1")
            if let pass = passes.first {
                storeService.delete(pass)
                isPresentingSaved = true
                savedPassName = "1-minute Break Pass"
                timerDistractedTime += distractionEndDate.timeIntervalSince(failTime)
                timerStartDate = failStartDate
                return
            }
        }
        if distractionEndDate.timeIntervalSince(failTime) <= 300 {
            let passes = storeService.items(of: "break-5")
            if let pass = passes.first {
                storeService.delete(pass)
                isPresentingSaved = true
                savedPassName = "5-minute Break Pass"
                timerDistractedTime += distractionEndDate.timeIntervalSince(failTime)
                timerStartDate = failStartDate
                return
            }
        }
        let coinsLost = (coins + 1) / 2
        let actualTime = failTime.timeIntervalSince(failStartDate) - timerDistractedTime
        let session = FocusSession(startDate: failStartDate, duration: timerSetting, coins: -coinsLost, actualDuration: actualTime, failed: true, task: workingTask)
        modelContext.insert(session)
        coins -= coinsLost // TODO: Extract to its own function
        isPresentingFailed = true
        hasFailedBuild = true
        workingTaskID = nil
        Task {
            try? await slackService.postMessage("FocusFlow: Failed focus session...\n* Actual focus time: \(actualTime.formatted(.timeInterval))")
        }
        Task {
            try? await slackService.clearStatus()
        }
    }
    
    // MARK: - Actions
    
    /// The user clicked the start button.
    func startTimer() {
        if !hintShown {
            isPresentingHint = true
        } else {
            timerDistractedTime = 0
            timerStartDate = Date.now
            Task {
                try? await slackService.postMessage("FocusFlow: Started focus session for \(timerSetting.formatted(.timeInterval))")
            }
            Task {
                try? await slackService.setStatus(text: "Focusing for \(timerSetting.formatted(.timeInterval)) | FocusFlow")
            }
        }
    }
    
    func decreaseTimer() {
        timerSetting -= 60
        timerSetting = max(60, timerSetting)
    }
    
    func increaseTimer() {
        timerSetting += 60
    }
    
    func chooseTask(_ task: ReminderTask) {
        workingTaskID = task.id
    }

    // MARK: - Utilities
    
    /// Calculate the number of coins the user gains, given the current state.
    func calculateCoins() -> Int {
        return Int(((timerSetting - timerDistractedTime) / 60).rounded(.up))
    }
    
    var workingTask: ReminderTask? {
        guard let workingTaskID else { return nil }
        return incompleteTasks.first { $0.id == workingTaskID }
    }
    
    enum SessionsScreenDestination {
        case value
    }
}

#Preview {
    let container = try! ModelContainer(for: FocusSession.self, configurations: .init(isStoredInMemoryOnly: true))
    HomeScreen()
        .environment(StoreService())
        .environment(SlackService())
        .modelContainer(container)
        .task {
            let context = container.mainContext
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759332600), duration: 3600, coins: 10, actualDuration: 3600))
            UserDefaults.standard.set(10, forKey: "coins")
            context.insert(ReminderTask(name: "test task"))
        }
}
