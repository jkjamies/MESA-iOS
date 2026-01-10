//
//  ContentView.swift
//  TrapezioCounter
//
//  Created by Jason Jamieson on 1/10/26.
//

import SwiftUI
import Trapezio

struct ContentView: View {
    var body: some View {
        CounterFactory.make(screen: CounterScreen(initialValue: 0))
    }
}

#Preview {
    CounterFactory.make(screen: CounterScreen(initialValue: 99))
}
