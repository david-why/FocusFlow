//
//  StringExtensions.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/4.
//

import Foundation

struct TimeIntervalFormatStyle: FormatStyle {
    func format(_ value: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .short
        return formatter.string(from: value) ?? "0s"
    }
}

extension FormatStyle where Self == TimeIntervalFormatStyle {
    static var timeInterval: TimeIntervalFormatStyle {
        TimeIntervalFormatStyle()
    }
}
