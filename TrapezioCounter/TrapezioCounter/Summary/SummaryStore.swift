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
import TrapezioStrata


@MainActor
final class SummaryStore: TrapezioStore<SummaryScreen, SummaryState, SummaryEvent> {
    private let navigator: (any TrapezioNavigator)?
    private let saveUseCase: SaveLastValueUseCase
    private let observeUseCase: ObserveLastValueUseCase

    init(screen: SummaryScreen, 
         navigator: (any TrapezioNavigator)?,
         saveUseCase: SaveLastValueUseCase,
         observeUseCase: ObserveLastValueUseCase) {
        self.navigator = navigator
        self.saveUseCase = saveUseCase
        self.observeUseCase = observeUseCase
        
        super.init(screen: screen, initialState: SummaryState(value: screen.value))
        
        // Start observing
        self.observe()
    }
    
    private func observe() {
        // Observe use case
        let stream = observeUseCase.createObservable(params: ())
        Task {
            for await val in stream {
                await MainActor.run {
                    self.update { $0.lastSavedValue = val }
                }
            }
        }
    }

    override func handle(event: SummaryEvent) {
        switch event {
        case .printValue:
            print("Trapezio Counter Value: \(state.value)")
        case .save:
            Task {
                // StrataInteractor returns a Result, does not throw directly
                let result = await saveUseCase.execute(params: state.value)
                result.onFailure { error in
                    print("Failed to save: \(error)")
                }
                // Success is handled by observation updating the state logic
            }
        case .back:
            navigator?.dismiss()
        }
    }
}
