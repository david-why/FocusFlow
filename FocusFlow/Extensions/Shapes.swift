//
//  Shapes.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/25.
//

import Foundation
import SwiftUI

// https://www.hackingwithswift.com/books/ios-swiftui/paths-vs-shapes-in-swiftui
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}
