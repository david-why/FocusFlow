//
//  SettingsScreen.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/25.
//

import SwiftUI

struct SettingsScreen: View {
    @AppStorage("slack-api-key") var slackAPIKey: String = ""
    @AppStorage("slack-channel") var slackChannel: String = ""
    
    @Environment(SlackService.self) var slackService
    
    @State var slackError: Error?
    @State var isShowingSlackError = false
    @State var isShowingSlackSuccess = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("xoxb-/xoxp- API Key", text: $slackAPIKey)
                    TextField("Channel ID", text: $slackChannel)
                    Button("Send a test message") {
                        Task {
                            await sendTestMessage()
                        }
                    }
                    .disabled(slackAPIKey.isEmpty || slackChannel.isEmpty)
                } header: {
                    Text("Slack Integration")
                } footer: {
                    Text("Enter a bot or user OAuth token and a channel to automatically post a message when you start focusing and complete a session. Check out [the Slack docs](https://api.slack.com) if you need help. The minimum required scope is `chat:write`.")
                }
            }
            .navigationTitle("Settings")
        }
        .alert("An error occurred", isPresented: $isShowingSlackError, presenting: slackError) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(verbatim: error.localizedDescription)
        }
        .alert("Success!", isPresented: $isShowingSlackSuccess) {} message: {
            Text("A test message was successfully sent to the specified channel!")
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
        } catch (let err) {
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
