//
//  CounterFactory.swift
//  Trapezio
//
//  Created by Jason Jamieson on 1/10/26.
//

import SwiftUI
import Trapezio
import TrapezioNavigation

struct CounterFactory {
    @ViewBuilder @MainActor
    static func make(screen: CounterScreen, navigator: (any TrapezioNavigator)?, interop: (any TrapezioInterop)?) -> some View {
        // This line is what DI code essentially does:
        // Look at dependency graph and provide the real impl.
        let usecase = DivideUsecase()
        
        TrapezioContainer(
            makeStore: CounterStore(screen: screen, divideUsecase: usecase, navigator: navigator, interop: interop),
            ui: CounterUI()
        )
    }
}
