//
//  CounterStore.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import Foundation
import Trapezio

final class CounterStore: TrapezioStore<CounterScreen, CounterState, CounterEvent> {
    private let divideUsecase = DivideUsecase()
    
    init(screen: CounterScreen) {
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
        case .printValue:
            print("Trapezio Counter Value: \(state.count)")
        }
    }
}
