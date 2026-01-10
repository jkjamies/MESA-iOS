//
//  TrapezioUI.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import SwiftUI

/// Maps state to pixels. Purely visual mapping.
public protocol TrapezioUI {
    associatedtype State: TrapezioState
    associatedtype Event: TrapezioEvent
    associatedtype Content: View
    
    @ViewBuilder
    func map(state: State, onEvent: @escaping (Event) -> Void) -> Content
}
