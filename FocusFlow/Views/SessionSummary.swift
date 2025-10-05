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
                durationField
                Text("\(coinText) \(session.coins.formatted(.number))")
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                Text(session.startDate.formatted(date: .omitted, time: .standard))
            }
        }
    }
    
    @ViewBuilder var durationField: some View {
        if session.failed {
            Text("\(formattedActualDuration) / \(formattedDuration)")
                .foregroundStyle(.red)
        } else if session.actualDuration != session.duration {
            Text(formattedDuration)
            + Text(" (\(formattedActualDuration))")
                .foregroundStyle(.secondary)
        } else {
            Text(formattedDuration)
        }
    }
    
    var formattedDuration: String {
        session.duration.formatted(.timeInterval.allowedUnits(.minute))
    }
    
    var formattedActualDuration: String {
        session.actualDuration.formatted(.timeInterval.allowedUnits([.minute, .second]))
    }
}

#Preview {
    SessionSummary(session: FocusSession(startDate: Date.now, duration: 1800, coins: 30, actualDuration: 1800))
}

#Preview("Failed") {
    SessionSummary(session: FocusSession(startDate: Date.now, duration: 1800, coins: -30, actualDuration: 30, failed: true))
}
