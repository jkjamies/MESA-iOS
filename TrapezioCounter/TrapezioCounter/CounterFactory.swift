//
//  CounterFactory.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import SwiftUI
import Trapezio

struct CounterFactory {
    @ViewBuilder
    static func make(screen: CounterScreen) -> some View {
        let store = CounterStore(screen: screen)
        
        // This is the clean, automated connection.
        store.render(with: CounterUI())
    }
}
