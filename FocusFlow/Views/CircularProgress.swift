//
//  CircularProgress.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/1.
//

import SwiftUI

struct CircularProgress: View {
    var percentage: Double
    
    var body: some View {
        // https://stackoverflow.com/a/70910572/13951118
        ZStack {
            Circle()
                .stroke(lineWidth: 16)
                .opacity(0.1)
            
            Circle()
                .trim(from: 0, to: percentage)
                .stroke(style: .init(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .rotationEffect(.degrees(270))
                .animation(.linear, value: percentage)
        }
    }
}

#Preview {
    @Previewable @State var percentage = 0.5
    CircularProgress(percentage: percentage)
        .frame(width: 200, height: 200)
        .task {
            for _ in 1...50 {
                try? await Task.sleep(for: .seconds(1))
                percentage += 0.01
            }
        }
}
