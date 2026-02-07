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

import SwiftUI
import Trapezio
import TrapezioNavigation
import SwiftData

struct SummaryFactory {
    @ViewBuilder @MainActor
    static func make(screen: SummaryScreen, navigator: (any TrapezioNavigator)?) -> some View {
        // Composition Root: Assemble dependencies
        let repo = SummaryRepositoryImpl(container: PersistenceService.shared.container)
        
        let saveUseCase = SaveLastValueUseCase(repository: repo)
        let observeUseCase = ObserveLastValueUseCase(repository: repo)
        
        return TrapezioContainer(
            makeStore: SummaryStore(screen: screen, 
                                    navigator: navigator,
                                    saveUseCase: saveUseCase,
                                    observeUseCase: observeUseCase),
            ui: SummaryUI()
        )
    }
}
