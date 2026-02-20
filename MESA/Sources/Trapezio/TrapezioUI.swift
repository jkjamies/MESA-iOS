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

/// A stateless view component that maps ``TrapezioState`` to SwiftUI content.
///
/// The UI layer is a pure function: given the same state, it always produces the same view tree.
/// User interactions are forwarded to the store via the `onEvent` callback — the UI never
/// performs logic or holds mutable state itself.
///
/// ```swift
/// struct CounterUI: TrapezioUI {
///     func map(state: CounterState, onEvent: @escaping @MainActor (CounterEvent) -> Void) -> some View {
///         Button("Count: \(state.count)") { onEvent(.increment) }
///     }
/// }
/// ```
///
/// - Important: Runs on `@MainActor`. Never perform async work or side effects inside `map`.
public protocol TrapezioUI {
    associatedtype State: TrapezioState
    associatedtype Event: TrapezioEvent
    associatedtype Content: View

    /// Renders the current state into a SwiftUI view.
    ///
    /// - Parameters:
    ///   - state: The current feature state to display.
    ///   - onEvent: Callback to emit user intents back to the ``TrapezioStore``.
    /// - Returns: The SwiftUI view tree for this state.
    @ViewBuilder
    func map(state: State, onEvent: @escaping @MainActor (Event) -> Void) -> Content
}
