//
//  ViewExtensions.swift
//  FocusFlow
//
//  Created by David Wang on 2025/10/5.
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder func `if`(_ condition: @autoclosure () -> Bool, transform: (Self) -> some View) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}
