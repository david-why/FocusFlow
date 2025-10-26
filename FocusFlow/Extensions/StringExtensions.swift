//
//  StringExtensions.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/4.
//

import Foundation

extension NSCalendar.Unit: @retroactive Codable, @retroactive Hashable {}
extension DateComponentsFormatter.UnitsStyle: @retroactive Codable {}

struct TimeIntervalFormatStyle: FormatStyle {
    private var allowedUnits: NSCalendar.Unit = [.hour, .minute, .second]
    private var unitsStyle = DateComponentsFormatter.UnitsStyle.short
    
    func allowedUnits(_ units: NSCalendar.Unit) -> Self {
        return TimeIntervalFormatStyle(allowedUnits: units, unitsStyle: unitsStyle)
    }
    
    func unitsStyle(_ style: DateComponentsFormatter.UnitsStyle) -> Self {
        return TimeIntervalFormatStyle(allowedUnits: allowedUnits, unitsStyle: style)
    }
    
    func format(_ value: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = allowedUnits
        formatter.unitsStyle = unitsStyle
        return formatter.string(from: value) ?? "0s"
    }
}

extension FormatStyle where Self == TimeIntervalFormatStyle {
    static var timeInterval: TimeIntervalFormatStyle {
        TimeIntervalFormatStyle()
    }
}

extension String {
    static let reminderListIDsKey = "reminder-list-ids"
}
