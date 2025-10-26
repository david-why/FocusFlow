//
//  TasksScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/26.
//

import SwiftUI
import SwiftData

struct TasksScreen: View {
    @Query var allTasks: [ReminderTask]
    
    @Environment(\.modelContext) var modelContext
    
    @State var addingTask: ReminderTask?
    
    var body: some View {
        NavigationStack {
            List {
                if incompleteTasks.isEmpty {
                    Text("Create a new task or set up Reminders sync in Settings!")
                }
                ForEach(incompleteTasks) { task in
                    NavigationLink(value: task) {
                        TaskSummary().environment(task)
                    }
                }
                .onDelete(perform: deleteIncompleteTasks)
            }
            .navigationTitle("Tasks")
            .toolbar {
                ToolbarItem {
                    Button("Add", systemImage: "plus", action: addTask)
                }
            }
            .navigationDestination(item: $addingTask) { task in
                EditTaskForm(type: .new).environment(task)
            }
            .navigationDestination(for: ReminderTask.self) { task in
                EditTaskForm().environment(task)
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
    
    func deleteIncompleteTasks(at indices: IndexSet) {
        let toDelete = indices.map { incompleteTasks[$0] }
        toDelete.forEach(modelContext.delete)
    }
    
    var incompleteTasks: [ReminderTask] {
        allTasks.filter { !$0.completed }
    }
}

struct TaskSummary: View {
    @Environment(ReminderTask.self) var task
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.completed ? "inset.filled.circle" : "circle")
                .opacity(0.7)
                .onTapGesture(perform: toggleCompleted)
            VStack(alignment: .leading) {
                Text(task.name)
                if let dueDate = task.dueDate {
                    Text(Image(systemName: "calendar.badge.clock"))
                        .foregroundStyle(.secondary)
                    + Text(" \(dueDate.formatted(date: .numeric, time: .shortened))")
                        .foregroundStyle(.secondary)
                }
                if let estimatedDuration = task.estimatedDuration {
                    Text(Image(systemName: "clock"))
                        .foregroundStyle(.secondary)
                    + Text(" \(estimatedDuration.formatted(.timeInterval))")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    func toggleCompleted() {
        withAnimation {
            task.completed.toggle()
        }
    }
}

#Preview {
    let container = try! ModelContainer(for: ReminderTask.self, configurations: .init(isStoredInMemoryOnly: true))
    TasksScreen()
        .modelContainer(container)
        .onAppear {
            let context = container.mainContext
            context.insert(ReminderTask(name: "english homework", dueDate: .now.addingTimeInterval(3600), estimatedDuration: 300))
        }
}
