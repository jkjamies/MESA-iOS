//
//  SummaryStore.swift
//  TrapezioCounter
//
//  Created by Jason Jamieson on 1/11/26.
//

import Foundation
import Trapezio
import TrapezioNavigation

@MainActor
final class SummaryStore: TrapezioStore<SummaryScreen, SummaryState, SummaryEvent> {
    private let navigator: (any TrapezioNavigator)?

    init(screen: SummaryScreen, navigator: (any TrapezioNavigator)?) {
        self.navigator = navigator
        super.init(screen: screen, initialState: SummaryState(value: screen.value))
    }

    override func handle(event: SummaryEvent) {
        switch event {
        case .printValue:
            print("Trapezio Counter Value: \(state.value)")
        case .back:
            navigator?.dismiss()
        }
    }
}
