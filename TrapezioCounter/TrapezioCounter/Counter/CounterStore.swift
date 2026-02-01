/*
 * Copyright 2026 Jason Jamieson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
