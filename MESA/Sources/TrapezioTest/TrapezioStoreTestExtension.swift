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

/// Extension enabling headless Store testing without UI.
///
/// Usage:
/// ```swift
/// let store = CounterStore(screen: CounterScreen(), ...)
/// store.test { state in
///     assert(state.count == 0)
/// }
///
/// store.handle(event: .increment)
/// store.test { state in
///     assert(state.count == 1)
/// }
/// ```
public extension TrapezioStore {
    /// Provides the current state for assertions after processing events.
    func test(validate: (State) -> Void) {
        validate(self.state)
    }

    /// Waits for state to settle after async work, then validates.
    ///
    /// - Parameters:
    ///   - timeout: Maximum time to wait for state to change.
    ///   - predicate: Condition to wait for before asserting.
    ///   - validate: Assertion block receiving the settled state.
    func awaitState(
        timeout: TimeInterval = 2.0,
        until predicate: @escaping (State) -> Bool,
        validate: @escaping (State) -> Void
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !predicate(state) && Date() < deadline {
            try? await Task.sleep(for: .milliseconds(50))
        }
        validate(state)
    }
}
