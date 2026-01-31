//
//  ContentView.swift
//  TrapezioCounter
//
//  Created by Jason Jamieson on 1/10/26.
//

import SwiftUI
import Trapezio
import TrapezioNavigation

struct ContentView: View {
    var body: some View {
        TrapezioNavigationHost(root: CounterScreen(initialValue: 0), onInterop: { event in
            // Handle interop events at the app root
            if let appEvent = event as? AppInterop {
                switch appEvent {
                case .showAlert(let message):
                    print("App Interop: Alert requested - \(message)")
                }
            }
        }) { screen, navigator, interop in
            switch screen {
            case let counter as CounterScreen:
                CounterFactory.make(screen: counter, navigator: navigator, interop: interop)
            case let summary as SummaryScreen:
                SummaryFactory.make(screen: summary, navigator: navigator)
            default:
                EmptyView()
            }
        }
    }
}

#Preview {
    TrapezioNavigationHost(root: CounterScreen(initialValue: 99)) { screen, navigator, interop in
        switch screen {
        case let counter as CounterScreen:
            CounterFactory.make(screen: counter, navigator: navigator, interop: interop)
        case let summary as SummaryScreen:
            SummaryFactory.make(screen: summary, navigator: navigator)
        default:
            EmptyView()
        }
    }
}
