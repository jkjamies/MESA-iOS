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
import Combine

@MainActor
open class TrapezioStore<S: TrapezioScreen, State: TrapezioState, Event: TrapezioEvent>: ObservableObject {
    public let screen: S
    @Published public private(set) var state: State
    
    public init(screen: S, initialState: State) {
        self.screen = screen
        self.state = initialState
    }
    
    open func handle(event: Event) { }
    
    public final func update(_ transform: (inout State) -> Void) {
        var copy = self.state
        transform(&copy)
        if copy != self.state {
            self.state = copy
        }
    }

    @MainActor
    public func render<U: TrapezioUI>(with ui: U) -> some View
    where U.State == State, U.Event == Event {
        TrapezioRuntime(presenter: self, ui: ui)
    }
}
