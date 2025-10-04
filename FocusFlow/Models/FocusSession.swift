//
//  FocusSession.swift
//  FocusFlow
//
//  Created by David Wang on 2025/9/30.
//

import Foundation
import SwiftData

@Model
class FocusSession {
    var startDate: Date
    var duration: TimeInterval
    var multiplier: Double
    @Relationship var task: ReminderTask? = nil
    
    init(startDate: Date, duration: TimeInterval, multiplier: Double, task: ReminderTask? = nil) {
        self.startDate = startDate
        self.duration = duration
        self.multiplier = multiplier
        self.task = task
    }
}
