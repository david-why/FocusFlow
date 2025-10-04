//
//  ReminderTask.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/2.
//

import Foundation
import SwiftData

@Model
class ReminderTask {
    var name: String
    var dueDate: Date // drop-dead due date
    var estimatedDuration: TimeInterval
    @Relationship var sessions = [FocusSession]()
    
    init(name: String, dueDate: Date, estimatedDuration: TimeInterval, sessions: [FocusSession] = []) {
        self.name = name
        self.dueDate = dueDate
        self.estimatedDuration = estimatedDuration
        self.sessions = sessions
    }
}
