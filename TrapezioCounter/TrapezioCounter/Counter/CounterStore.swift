//
//  CounterStore.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import Foundation
import Trapezio
import TrapezioNavigation

@MainActor
final class CounterStore: TrapezioStore<CounterScreen, CounterState, CounterEvent> {
    private let divideUsecase: any DivideUsecaseProtocol
    private let navigator: (any TrapezioNavigator)?
    private let interop: (any TrapezioInterop)?
    
    init(
        screen: CounterScreen,
        divideUsecase: any DivideUsecaseProtocol,
        navigator: (any TrapezioNavigator)?,
        interop: (any TrapezioInterop)?
    ) {
        self.divideUsecase = divideUsecase
        self.navigator = navigator
        self.interop = interop
        super.init(screen: screen, initialState: CounterState(count: screen.initialValue))
    }
    
    override func handle(event: CounterEvent) {
        switch event {
        case .increment:
            update { $0.count += 1 }
        case .decrement:
            update { $0.count -= 1 }
        case .divideByTwo:
            Task {
                let result = await divideUsecase.execute(value: state.count)
                update { $0.count = result }
            }
        case .goToSummary:
            navigator?.goTo(SummaryScreen(value: state.count))
        case .requestHelp:
            interop?.send(AppInterop.showAlert(message: "This is a simple counter. Press +/- to change value."))
        }
    }
}
