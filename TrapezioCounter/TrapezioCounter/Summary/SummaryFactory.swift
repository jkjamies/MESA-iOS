//
//  SummaryFactory.swift
//  TrapezioCounter
//
//  Created by Jason Jamieson on 1/11/26.
//

import SwiftUI
import Trapezio
import TrapezioNavigation

struct SummaryFactory {
    @ViewBuilder @MainActor
    static func make(screen: SummaryScreen, navigator: (any TrapezioNavigator)?) -> some View {
        TrapezioContainer(
            makeStore: SummaryStore(screen: screen, navigator: navigator),
            ui: SummaryUI()
        )
    }
}
