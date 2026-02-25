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

/// The SwiftUI lifecycle owner for Trapezio stores.
///
/// Use this whenever you render a store in SwiftUI so the store isn't recreated
/// during view updates (e.g. when navigating or when parent views re-render).
public struct TrapezioContainer<Store: ObservableObject, Content: View>: View {

    @StateObject private var store: Store
    private let content: (Store) -> Content

    public init(
        makeStore: @escaping @autoclosure () -> Store,
        @ViewBuilder content: @escaping (Store) -> Content
    ) {
        _store = StateObject(wrappedValue: makeStore())
        self.content = content
    }

    public var body: some View {
        content(store)
    }
}

public extension TrapezioContainer {
    /// Convenience initializer for the common Trapezio pattern: `TrapezioStore + TrapezioUI`.
    init<S: TrapezioScreen, State: TrapezioState, Event: TrapezioEvent, UI: TrapezioUI>(
        makeStore: @escaping @autoclosure () -> TrapezioStore<S, State, Event>,
        ui: UI
    ) where Store == TrapezioStore<S, State, Event>, Content == AnyView, UI.State == State, UI.Event == Event {
        _store = SwiftUI.StateObject(wrappedValue: makeStore())
        self.content = { store in
            AnyView(store.render(with: ui))
        }
    }
}
