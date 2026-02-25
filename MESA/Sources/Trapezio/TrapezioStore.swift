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

/// The single source of truth for a feature's presentation logic.
///
/// `TrapezioStore` is the brain of every MESA feature. It holds the current ``State``,
/// receives user intents as ``Event`` values, and mutates state via ``update(_:)``.
/// SwiftUI observes state changes through `ObservableObject` conformance.
///
/// Subclass this for each feature and override ``handle(event:)`` to map events to state changes:
///
/// ```swift
/// final class CounterStore: TrapezioStore<CounterScreen, CounterState, CounterEvent> {
///     override func handle(event: CounterEvent) {
///         switch event {
///         case .increment: update { $0.count += 1 }
///         case .decrement: update { $0.count -= 1 }
///         }
///     }
/// }
/// ```
///
/// - Important: This class is `@MainActor`. All state reads/writes happen on the main thread.
/// - Note: Use ``TrapezioContainer`` to preserve store identity across SwiftUI view updates.
@MainActor
open class TrapezioStore<S: TrapezioScreen, State: TrapezioState, Event: TrapezioEvent>: ObservableObject, Identifiable {
    public let screen: S
    /// Current state snapshot. Readable from any isolation context (value-type copy).
    /// Writes are restricted to ``update(_:)`` on the `@MainActor`.
    nonisolated(unsafe) public private(set) var state: State

    /// Creates a store with its associated screen and initial state.
    ///
    /// - Parameters:
    ///   - screen: The screen descriptor that identifies this feature in navigation.
    ///   - initialState: The starting state rendered on first appearance.
    public init(screen: S, initialState: State) {
        self.screen = screen
        self.state = initialState
    }

    /// Override this method to map user events to state mutations.
    ///
    /// Called by the runtime whenever the UI emits an event. The default implementation is a no-op.
    ///
    /// - Parameter event: The user intent to handle.
    open func handle(event: Event) { }

    /// Mutates state using copy-on-write semantics.
    ///
    /// Creates a mutable copy of the current state, applies `transform`, and only publishes
    /// the new state if it differs from the current value (checked via `Equatable`).
    /// This prevents unnecessary SwiftUI re-renders.
    ///
    /// - Parameter transform: A closure that mutates the state copy in place.
    public final func update(_ transform: (inout State) -> Void) {
        var copy = self.state
        transform(&copy)
        if copy != self.state {
            self.objectWillChange.send()
            self.state = copy
        }
    }

    /// Binds this store to a ``TrapezioUI`` and returns the rendered SwiftUI view.
    ///
    /// - Parameter ui: The UI component that maps state to pixels.
    /// - Returns: A view that observes this store's state and routes events back to ``handle(event:)``.
    public func render<U: TrapezioUI>(with ui: U) -> some View
    where U.State == State, U.Event == Event {
        TrapezioRuntime(presenter: self, ui: ui)
    }
}
