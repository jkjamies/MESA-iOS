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
        self.setupBindings()
    }
    
    private func setupBindings() {
        // Observe last saved value
        let stream = observeUseCase.createObservable(params: ())
        strataCollect(stream) { [weak self] val in
            self?.update { $0.lastSavedValue = val }
        }
        
        // Observe save usecase inProgress state (Trapeze pattern)
        strataCollect(saveUseCase.inProgressStream) { [weak self] isLoading in
            self?.update { $0.isLoading = isLoading }
        }
    }

    override func handle(event: SummaryEvent) {
        switch event {
        case .printValue:
            print("Trapezio Counter Value: \(state.value)")
        case .save:
            strataLaunch {
                let result = await self.saveUseCase.execute(params: self.state.value)
                result.onSuccess { _ in
                    print("Value saved successfully.")
                }.onFailure { (error: any StrataException) in
                    print("Failed to save: \(error.message)")
                }
            }
        case .back:
            navigator?.dismiss()
        }
    }
}
