//
//  EventKitService.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/26.
//

import Foundation
import EventKit

extension UserDefaults {
    @objc dynamic var reminderListIDs: [String] {
        stringArray(forKey: .reminderListIDsKey) ?? []
    }
}

@Observable
class EventKitService {
    let eventStore: EKEventStore
    let userDefaults: UserDefaults
    
    private var accessGranted = false {
        willSet {
            if !accessGranted && newValue {
                registerNotifications()
                updateReminderLists()
                Task {
                    await updateReminders()
                }
            }
        }
    }
    private var observation: NSKeyValueObservation?
    
    private(set) var reminders: [AppleReminder] = []
    private(set) var reminderLists: [AppleReminderList] = []
    
    init(eventStore: EKEventStore?, userDefaults: UserDefaults?) {
        self.eventStore = eventStore ?? EKEventStore()
        self.userDefaults = userDefaults ?? UserDefaults.standard
        observation = self.userDefaults.observe(\.reminderListIDs) { _, _ in
            self.onReminderListIDsChanged()
        }
    }
    
    deinit {
        unregisterNotifications()
    }
    
    func requestAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            Task { @MainActor in
                accessGranted = granted
            }
            return granted
        } catch let err {
            print("Error requesting reminder access :(")
            print(err)
            return false
        }
    }
    
    // MARK: - Helper functions
    
    private func updateReminders() async {
        guard accessGranted else { return }
        
        let calendars = eventStore.calendars(for: .reminder).filter { reminderListIDs.contains($0.calendarIdentifier) }
        guard !calendars.isEmpty else {
            Task { @MainActor in
                reminders = []
            }
            return
        }
        
        let predicate = eventStore.predicateForReminders(in: calendars)
        guard let ekReminders = await eventStore.fetchReminders(matching: predicate) else {
            print("Got nil for reminders??")
            Task { @MainActor in
                reminders = []
            }
            return
        }
        
        let appleReminders = ekReminders.map(AppleReminder.init)
        
        Task { @MainActor in
            reminders = appleReminders
        }
    }
    
    private func updateReminderLists() {
        guard accessGranted else { return }
        
        let ekCalendars = eventStore.calendars(for: .reminder)
        
        Task { @MainActor in
            let appleReminderLists = ekCalendars.map(AppleReminderList.init)
            reminderLists = appleReminderLists
        }
    }
    
    private func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(onStoreChanged), name: .EKEventStoreChanged, object: eventStore)
    }
    
    private func unregisterNotifications() {
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: eventStore)
    }
    
    // MARK: - Events
    
    @objc private func onStoreChanged(_: EKEventStore) {
        Task {
            await updateReminders()
        }
        updateReminderLists()
    }
    
    private func onReminderListIDsChanged() {
        Task {
            await updateReminders()
        }
    }
    
    // MARK: - UserDefaults
    
    var reminderListIDs: [String] {
        userDefaults.reminderListIDs
    }
}

@Observable
class AppleReminder {
    private let reminder: EKReminder
    
    init(reminder: EKReminder) {
        self.reminder = reminder
    }
    
    var title: String {
        reminder.title
    }
    
    var notes: String? {
        reminder.notes
    }
    
    var dueDate: Date? {
        guard let components = reminder.dueDateComponents else { return nil }
        return Calendar(identifier: .gregorian).date(from: components)
    }
}

@Observable
class AppleReminderList {
    private let calendar: EKCalendar
    
    init(calendar: EKCalendar) {
        self.calendar = calendar
    }
    
    var title: String {
        calendar.title
    }
    
    var color: CGColor {
        calendar.cgColor
    }
}
