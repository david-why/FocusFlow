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
    var coins: Int
    @Relationship var task: ReminderTask? = nil
    
    init(startDate: Date, duration: TimeInterval, coins: Int, task: ReminderTask? = nil) {
        self.startDate = startDate
        self.duration = duration
        self.coins = coins
        self.task = task
    }
}
