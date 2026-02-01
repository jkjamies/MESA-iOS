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
