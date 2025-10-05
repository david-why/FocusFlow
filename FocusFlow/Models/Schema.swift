//
//  Schema.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/5.
//

import Foundation
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] = [FocusSession.self, ReminderTask.self]
    
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
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] = [FocusSession.self, ReminderTask.self]
    
    @Model
    class FocusSession {
        var startDate: Date
        var duration: TimeInterval
        var coins: Int
        /// The amount of time actually spent focusing (equal to duration
        /// when `!failed`).
        var actualDuration: TimeInterval = 0
        var failed: Bool = false
        @Relationship var task: ReminderTask? = nil
        
        init(startDate: Date, duration: TimeInterval, coins: Int, actualDuration: TimeInterval = 0, failed: Bool = false, task: ReminderTask? = nil) {
            self.startDate = startDate
            self.duration = duration
            self.coins = coins
            self.actualDuration = actualDuration
            self.failed = failed
            self.task = task
        }
    }
    
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
}

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self
    ]
    
    static var stages = [
        migrateV1toV2
    ]
    
    static let migrateV1toV2 = MigrationStage.custom(fromVersion: SchemaV1.self, toVersion: SchemaV2.self, willMigrate: nil) { context in
        print("Selecting models to add actualDuration")
        var models = try context.fetch(FetchDescriptor<SchemaV2.FocusSession>())
        print("Model count: \(models.count)")
        for model in models {
            if !model.failed {
                model.actualDuration = model.duration
            } else {
                model.actualDuration = 0
            }
            print("Model \(model) has actual duration \(model.actualDuration)")
        }
        try context.save()
    }
}

typealias CurrentSchema = SchemaV2
typealias FocusSession = CurrentSchema.FocusSession
typealias ReminderTask = CurrentSchema.ReminderTask
