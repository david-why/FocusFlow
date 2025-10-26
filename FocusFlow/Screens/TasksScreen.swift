//
//  TasksScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/26.
//

import SwiftUI
import SwiftData

struct TasksScreen: View {
    @Query<ReminderTask>(filter: #Predicate { !$0.completed }) private var incompleteTasks: [ReminderTask]
    
    @Environment(\.modelContext) var modelContext
    
    @State var addingTask: ReminderTask?
    
    var body: some View {
        NavigationStack {
            List {
                if incompleteTasks.isEmpty {
                    Text("Create a new task or set up Reminders sync in Settings!")
                }
                ForEach(incompleteTasks) { task in
                    Text(task.name)
                }
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem {
                    Button("Add", systemImage: "plus", action: addTask)
                }
            }
            .navigationDestination(item: $addingTask) { task in
                EditTaskForm(type: .new)
                    .environment(task)
            }
            .onChange(of: addingTask) { old, new in
                if let old, new == nil {
                    // came back from the adding page
                    if !old.name.isEmpty {
                        modelContext.insert(old)
                    }
                }
            }
        }
    }
    
    func addTask() {
        addingTask = ReminderTask(name: "")
    }
}

#Preview {
    TasksScreen()
        .modelContainer(for: ReminderTask.self, inMemory: true, isAutosaveEnabled: true)
}
