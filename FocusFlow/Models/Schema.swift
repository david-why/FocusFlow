//
//  Schema.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/5.
//

import Foundation
import SwiftData
import SwiftUI

struct RGBColor: Codable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    init(red: Double, green: Double, blue: Double, opacity: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }
    
    init(_ color: Color) {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var opacity: CGFloat = 0
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &opacity)
        self.init(red: red, green: green, blue: blue, opacity: opacity)
    }
    
    static let black = RGBColor(red: 0, green: 0, blue: 0, opacity: 1)
    static let red = RGBColor(red: 1, green: 0.2196, blue: 0.2353, opacity: 1)
    
    static var random: RGBColor {
        RGBColor(red: .random(in: 0...1), green: .random(in: 0...1), blue: .random(in: 0...1), opacity: 1)
    }
    
    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: opacity)
    }
}

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
        var id: String = UUID().uuidString
        var name: String
        var dueDate: Date? // drop-dead due date
        var estimatedDuration: TimeInterval?
        var completed: Bool = false
        var reminderIdentifier: String?
        @Relationship var sessions = [FocusSession]()
        
        init(name: String, dueDate: Date? = nil, estimatedDuration: TimeInterval? = nil, completed: Bool = false, reminderIdentifier: String? = nil, sessions: [FocusSession] = []) {
            self.name = name
            self.dueDate = dueDate
            self.estimatedDuration = estimatedDuration
            self.completed = completed
            self.reminderIdentifier = reminderIdentifier
            self.sessions = sessions
        }
    }
    
    @Model
    class BuildingItem {
        var content: BuildingItemContent
        var offsetX: Double
        var offsetY: Double
        var zIndex: Double
        var width: Double
        var height: Double
        var rotation: Double
        
        init(content: BuildingItemContent, offsetX: Double, offsetY: Double, zIndex: Double, width: Double, height: Double, rotation: Double) {
            self.content = content
            self.offsetX = offsetX
            self.offsetY = offsetY
            self.zIndex = zIndex
            self.width = width
            self.height = height
            self.rotation = rotation
        }
    }
    
    enum BuildingItemContent: Codable {
        case image(name: String)
        case rect(color: RGBColor)
        case triangle(color: RGBColor)
        case ellipse(color: RGBColor)
    }
}

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] = [
        SchemaV1.self,
        SchemaV2.self,
    ]
    
    static var stages = [
        migrateV1toV2,
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
typealias BuildingItem = CurrentSchema.BuildingItem
typealias BuildingItemContent = CurrentSchema.BuildingItemContent
