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
    
    var body: some View {
        Color.clear
            .frame(height: 20)
        Text("FocusFlow")
            .font(.largeTitle.bold())
            .padding(.bottom, 8)
        Text("\(coinText) \(coins)")
        Spacer()
        progressView
        buttonsView
            .padding(.top, 20)
        Spacer()
        Text("Last session")
            .foregroundStyle(.secondary)
        VStack {
            lastSessionView
                .padding()
                .background(.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)
        Spacer()
            .onReceive(timer, perform: onTimerTick)
            .alert("You did it!", isPresented: $isPresentingCongrats) {} message: {
                Text("You focused for \(timerSetting.formatted(.timeInterval.allowedUnits(.minute).unitsStyle(.full)))! Enjoy your reward of \(lastCoinGain) coins!")
            }
    }
    
    @AppStorage("coins") var coins: Int = 0
    
    @State var lastCoinGain = 0
    @State var isPresentingCongrats = false
    
    // MARK: - Timer state
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State var now = Date.now
    
    @State var timerSetting = TimeInterval(5) // TODO: change me back to 1800
    @State var timerStartDate: Date? = nil
    
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

                Text("\(Image(systemName: "alarm")) \(progressAlarmTime)")
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .foregroundStyle(.secondary)
                    .background(Color.accentColor.opacity(0.2), in: Capsule())
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
            Spacer()
            actionButton(systemImage: timerRunning ? "stop" : "play", style: .borderedProminent, action: startTimer)
            Spacer()
            actionButton(systemImage: "plus", action: increaseTimer)
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
        HStack {
            if let lastSession {
                VStack(alignment: .leading) {
                    Text(lastSession.duration.formatted(.timeInterval.allowedUnits(.minute)))
                    Text("\(coinText) \(lastSession.coins.formatted(.number))")
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(lastSession.startDate.formatted(date: .abbreviated, time: .omitted))
                    Text(lastSession.startDate.formatted(date: .omitted, time: .standard))
                }
            } else {
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
        let session = FocusSession(startDate: timerStartDate, duration: timerSetting, coins: coinsWon)
        modelContext.insert(session)
        coins += coinsWon
        self.timerStartDate = nil
        lastCoinGain = coinsWon
        isPresentingCongrats = true
    }
    
    // MARK: - Actions
    
    /// The user started the timer.
    func startTimer() {
        timerStartDate = Date.now
    }
    
    // MARK: - Utilities
    
    /// Calculate the number of coins the user gains, given the current state.
    func calculateCoins() -> Int {
        return Int((timerSetting / 60).rounded(.up))
    }
    
    func decreaseTimer() {
        timerSetting -= 60
        timerSetting = max(60, timerSetting)
    }
    
    func increaseTimer() {
        timerSetting += 60
    }
}

#Preview {
    let container = try! ModelContainer(for: FocusSession.self, configurations: .init(isStoredInMemoryOnly: true))
    HomeScreen()
        .modelContainer(container)
        .task {
            let context = container.mainContext
            context.insert(FocusSession(startDate: Date(timeIntervalSince1970: 1759332600), duration: 3600, coins: 10))
            UserDefaults.standard.set(10, forKey: "coins")
        }
}
