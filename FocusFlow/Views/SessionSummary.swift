//
//  SessionSummary.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/4.
//

import SwiftUI

struct SessionSummary: View {
    let session: FocusSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(session.duration.formatted(.timeInterval.allowedUnits(.minute)))
                Text("\(coinText) \(session.coins.formatted(.number))")
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                Text(session.startDate.formatted(date: .omitted, time: .standard))
            }
        }
    }
}

#Preview {
    SessionSummary(session: FocusSession(startDate: Date.now, duration: 1800, coins: 30))
}
