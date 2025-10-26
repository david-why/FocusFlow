//
//  SlackService.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/25.
//

import Foundation

struct SlackAPIResponse: Codable {
    var ok: Bool
    var error: String?
}

@Observable
class SlackService {
    private var messageEnabled: Bool {
        UserDefaults.standard.bool(forKey: "slack-should-message")
    }
    private var oauthToken: String? {
        UserDefaults.standard.string(forKey: "slack-api-key")
    }
    private var channel: String? {
        UserDefaults.standard.string(forKey: "slack-channel")
    }
    
    private var statusEnabled: Bool {
        UserDefaults.standard.bool(forKey: "slack-should-status")
    }
    private var statusOAuthToken: String? {
        UserDefaults.standard.string(forKey: "slack-status-api-key")
    }
    private var statusEmoji: String? {
        UserDefaults.standard.string(forKey: "slack-status-emoji")
    }
    
    private func makeRequest(endpoint: String, method: String = "GET", payload: Any? = nil, token: String? = nil) async throws -> SlackAPIResponse? {
        guard let oauthToken = token ?? oauthToken else { return nil }
        let url = URL(string: "https://slack.com/api/\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer " + oauthToken, forHTTPHeaderField: "Authorization")
        
        if let payload {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        }
        
        let (resData, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SlackAPIResponse.self, from: resData)
        
        return response
    }
    
    func postMessage(_ text: String) async throws -> SlackAPIResponse? {
        guard let channel, messageEnabled else { return nil }
        
        let payload = [
            "channel": channel,
            "text": text
        ]
        return try await makeRequest(endpoint: "chat.postMessage", method: "POST", payload: payload)
    }
    
    func setStatus(text: String, expiration: Date? = nil) async throws -> SlackAPIResponse? {
        guard let statusOAuthToken, let statusEmoji, statusEnabled else { return nil }
        
        let payload = [
            "profile": [
                "status_text": text,
                "status_emoji": statusEmoji,
                "status_expiration": Int(expiration?.timeIntervalSince1970 ?? 0)
            ]
        ]
        return try await makeRequest(endpoint: "users.profile.set", method: "POST", payload: payload, token: statusOAuthToken)
    }
    
    func clearStatus() async throws -> SlackAPIResponse? {
        guard let statusOAuthToken, statusEnabled else { return nil }
        
        let payload = [
            "profile": [
                "status_text": "",
                "status_emoji": "",
                "status_expiration": 0
            ]
        ]
        return try await makeRequest(endpoint: "users.profile.set", method: "POST", payload: payload, token: statusOAuthToken)
    }
}
