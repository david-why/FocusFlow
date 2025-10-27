//
//  SettingsScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/25.
//

import SwiftUI

struct SettingsScreen: View {
    @AppStorage("slack-api-key") var slackAPIKey: String = ""
    @AppStorage("slack-should-message") var slackShouldMessage = false
    @AppStorage("slack-channel") var slackChannel: String = ""
    
    @AppStorage("slack-should-status") var slackShouldStatus = false
    @AppStorage("slack-status-api-key") var slackStatusAPIKey = ""
    @AppStorage("slack-status-emoji") var slackStatusEmoji = ""
    
    @AppStorage("eventkit-tasks-synced") var tasksSynced = false
    @AppStorage(.reminderListIDKey) var reminderListID: String?

    @Environment(SlackService.self) var slackService
    
    @State var slackError: Error?
    @State var isShowingSlackError = false
    @State var isShowingSlackSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Post messages in Slack?", isOn: $slackShouldMessage)
                    
                    if slackShouldMessage {
                        SecureField("xoxb-/xoxp- API Key", text: $slackAPIKey)
                        
                        TextField("Channel ID", text: $slackChannel)
                        Button("Send a test message") {
                            Task {
                                await sendTestMessage()
                            }
                        }
                        .disabled(slackAPIKey.isEmpty || slackChannel.isEmpty)
                    }
                } header: {
                    Text("Slack Notifications")
                } footer: {
                    Text("Enter a bot or user OAuth token and a channel to automatically post a message when you start focusing and complete a session. Check out [the Slack docs](https://api.slack.com) if you need help. The minimum required scope is `chat:write`.")
                }
                
                Section {
                    Toggle("Update Slack status?", isOn: $slackShouldStatus)
                    if slackShouldStatus {
                        SecureField("xoxp- API Key", text: $slackStatusAPIKey)
                        TextField("Emoji (e.g. :pencil:)", text: $slackStatusEmoji)
                        Button("Test status updating") {
                            Task {
                                await testUpdateStatus()
                            }
                        }
                        .disabled(slackStatusAPIKey.isEmpty || slackStatusEmoji.isEmpty)
                    }
                } header: {
                    Text("Slack Status Updates")
                } footer: {
                    Text("Enter a user OAuth token and an emoji to update your status when you are in a focus session. This will clear your status after the session ends. The minimum required scope is `users.profile:write`.")
                }
                
                Section {
                    Toggle("Sync with Reminders?", isOn: $tasksSynced)
                    if tasksSynced {
                        ReminderListPicker(value: $reminderListID)
                            .pickerStyle(.menu)
                    }
                } header: {
                    Text("Reminders Sync")
                } footer: {
                    Text("Automatically add new Reminders to the Tasks section.")
                }
            }
            .navigationTitle("Settings")
        }
        .animation(.default, value: slackShouldMessage)
        .animation(.default, value: slackShouldStatus)
        .alert("An error occurred", isPresented: $isShowingSlackError, presenting: slackError) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(verbatim: error.localizedDescription)
        }
        .alert("Success!", isPresented: $isShowingSlackSuccess) {} message: {
            Text("The test was completed successfully!")
        }
    }
    
    func sendTestMessage() async {
        do {
            guard let response = try await slackService.postMessage("TEST") else {
                throw SettingsScreenError.slackNoResponse
            }
            if let error = response.error {
                throw SettingsScreenError.slackAPIError(error: error)
            }
            isShowingSlackSuccess = true
        } catch let err {
            slackError = err
            isShowingSlackError = true
        }
    }
    
    func testUpdateStatus() async {
        do {
            guard let response = try await slackService.setStatus(text: "FocusFlow") else {
                throw SettingsScreenError.slackNoResponse
            }
            if let error = response.error {
                throw SettingsScreenError.slackAPIError(error: error)
            }
            isShowingSlackSuccess = true
        } catch let err {
            slackError = err
            isShowingSlackError = true
        }
    }
}

enum SettingsScreenError: LocalizedError {
    case slackNoResponse
    case slackAPIError(error: String)
    
    var errorDescription: String? {
        switch self {
        case .slackNoResponse: "The API call failed."
        case .slackAPIError(let error): "The Slack API call failed with error: \(error)."
        }
    }
}

#Preview {
    SettingsScreen()
        .environment(SlackService())
}
