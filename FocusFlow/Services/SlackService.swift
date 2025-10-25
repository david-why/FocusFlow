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
    private var oauthToken: String? {
        UserDefaults.standard.string(forKey: "slack-api-key")
    }
    
    private var channel: String? {
        UserDefaults.standard.string(forKey: "slack-channel")
    }
    
    func postMessage(_ text: String) async throws -> SlackAPIResponse? {
        guard let oauthToken, let channel else { return nil }
        
        let url = URL(string: "https://slack.com/api/chat.postMessage")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer " + oauthToken, forHTTPHeaderField: "Authorization")
        
        let payload = [
            "channel": channel,
            "text": text
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (resData, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(SlackAPIResponse.self, from: resData)
        
        return response
    }
}
