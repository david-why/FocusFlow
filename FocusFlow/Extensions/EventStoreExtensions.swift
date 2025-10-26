//
//  EventStoreExtensions.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/26.
//

import Foundation
import EventKit

extension EKEventStore {
    func fetchReminders(matching predicate: NSPredicate) async -> [EKReminder]? {
        return await withCheckedContinuation { continuation in
            fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders)
            }
        }
    }
}
