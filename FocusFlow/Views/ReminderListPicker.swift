//
//  ReminderListPicker.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/27.
//

import SwiftUI

struct ReminderListPicker: View {
    @Binding var value: String?
    
    @Environment(EventKitService.self) var eventKitService
    @Environment(\.dismiss) var dismiss
    
    @State var grantedAccess = false
    
    var body: some View {
        Picker("Reminder list", selection: $value) {
            if grantedAccess {
                ForEach(eventKitService.reminderLists) { list in
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundStyle(Color(cgColor: list.color))
                        Text(list.title)
                    }
                    .tag(list.id)
                }
            }
        }
        .pickerStyle(.navigationLink)
        .task {
            grantedAccess = await eventKitService.requestAccess()
            guard grantedAccess else {
                dismiss()
                return
            }
        }
    }
}

#Preview {
    @Previewable @State var value: String?
    
    ReminderListPicker(value: $value)
}
