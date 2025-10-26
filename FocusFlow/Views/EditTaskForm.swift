//
//  EditTaskForm.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/26.
//

import SwiftUI
import SwiftData

struct EditTaskForm: View {
    var type = FormType.edit
    
    @Environment(ReminderTask.self) private var task
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var estimatedHours = 0
    @State private var estimatedMinutes = 0
    
    @State private var isPickingDuration = false
    
    var body: some View {
        @Bindable var task = self.task
        
        Form {
            TextField("Name", text: $task.name)
            
            Toggle("Has deadline", isOn: hasDueDateBinding)
            if hasDueDateBinding.wrappedValue {
                DatePicker("Deadline", selection: dueDateBinding)
                    .datePickerStyle(.compact)
            }
            
            LabeledContent("Estimated duration") {
                Button {
                    isPickingDuration.toggle()
                } label: {
                    Text("\(estimatedHours)h \(estimatedMinutes)m")
                }
            }
            if isPickingDuration {
                HStack {
                    Picker("Hours", selection: $estimatedHours) {
                        ForEach(0...23, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                    Text("h")
                    Picker("Minutes", selection: $estimatedMinutes) {
                        ForEach(0...59, id: \.self) { i in
                            Text("\(i)").tag(i)
                        }
                    }
                }
                .pickerStyle(.wheel)
            }
        }
        .navigationTitle(type == .new ? "New task" : "Edit task")
        .toolbar {
            if #available(iOS 26.0, *) {
                Button("Done", role: .confirm) {
                    dismiss()
                }
            } else {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .animation(.default, value: isPickingDuration)
    }
    
    var hasDueDateBinding: Binding<Bool> {
        Binding {
            task.dueDate != nil
        } set: { value in
            if value && task.dueDate == nil {
                task.dueDate = Calendar.current.startOfDay(for: .now.addingTimeInterval(86400))
            } else if !value && task.dueDate != nil {
                task.dueDate = nil
            }
        }
    }
    
    var dueDateBinding: Binding<Date> {
        Binding {
            task.dueDate ?? Calendar.current.startOfDay(for: .now.addingTimeInterval(86400))
        } set: { value in
            task.dueDate = value
        }
    }
    
    enum FormType {
        case new
        case edit
    }
}

#Preview {
    let modelContainer = try! ModelContainer(for: ReminderTask.self, configurations: .init(isStoredInMemoryOnly: true))
    NavigationStack {
        EditTaskForm()
    }
    .modelContainer(modelContainer)
    .environment(ReminderTask(name: ""))
}
