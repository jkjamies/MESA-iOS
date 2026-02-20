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
import Observation
import Trapezio
import os

/// A lightweight SwiftUI host that owns a `NavigationStack` and a library-managed `TrapezioNavigator`.
///
/// You provide:
/// - A root `TrapezioScreen`
/// - A builder that can render any `TrapezioScreen` using your factories/DI
///
/// Features can request navigation by calling `navigator.goTo(...)` / `dismiss()`.
public struct TrapezioNavigationHost: View {

    /// Receives custom navigation/dismissal requests for legacy interop.
    public typealias InteropHandler = (_ event: TrapezioInteropEvent) -> Void

    @State private var navigator: TrapezioStackNavigator

    private let builder: (any TrapezioScreen, any TrapezioNavigator, any TrapezioInterop) -> AnyView

    /// - Parameters:
    ///   - root: Root screen for the navigation stack.
    ///   - onInterop: Called when a feature emits a custom interop event.
    ///   - builder: Renders a screen into a view. The provided navigator is owned by this host.
    public init<Content: View>(
        root: any TrapezioScreen,
        onInterop: InteropHandler? = nil,
        @ViewBuilder builder: @escaping (_ screen: any TrapezioScreen, _ navigator: any TrapezioNavigator, _ interop: any TrapezioInterop) -> Content
    ) {
        _navigator = State(wrappedValue: TrapezioStackNavigator(root: root, onInterop: onInterop))
        self.builder = { (screen: any TrapezioScreen, navigator: any TrapezioNavigator, interop: any TrapezioInterop) -> AnyView in
            AnyView(builder(screen, navigator, interop))
        }
    }

    public var body: some View {
        NavigationStack(path: $navigator.path) {
            rootView
                .navigationDestination(for: TrapezioAnyScreen.self) { anyScreen in
                    builder(anyScreen.base, navigator, navigator.interop)
                }
        }
    }

    private var rootView: some View {
        if let root = navigator.root {
            return builder(root, navigator, navigator.interop)
        }
        return AnyView(EmptyView())
    }
}

/// Type-erased `TrapezioScreen` wrapper used as a `NavigationStack` path element.
internal struct TrapezioAnyScreen: Hashable {
    public let id: UUID
    public let base: any TrapezioScreen

    public init(_ base: any TrapezioScreen, id: UUID = UUID()) {
        self.id = id
        self.base = base
    }

    public static func == (lhs: TrapezioAnyScreen, rhs: TrapezioAnyScreen) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

private let logger = Logger(subsystem: "Trapezio", category: "Navigation")

/// A library-owned navigator that drives a `NavigationStack` by mutating its path.
@MainActor
@Observable
internal final class TrapezioStackNavigator: TrapezioNavigator {

    internal var path: [TrapezioAnyScreen] = []
    internal var root: (any TrapezioScreen)?
    
    internal let interop: any TrapezioInterop

    internal init(root: any TrapezioScreen, onInterop: TrapezioNavigationHost.InteropHandler?) {
        self.root = root
        self.interop = ClosureTrapezioInterop { event in
            onInterop?(event)
        }
    }

    internal func goTo(_ screen: any TrapezioScreen) {
        path.append(TrapezioAnyScreen(screen))
    }

    internal func dismiss() {
        guard !path.isEmpty else { return }
        _ = path.popLast()
    }

    internal func dismissToRoot() {
        path.removeAll()
    }
    
    internal func dismissTo(_ screen: any TrapezioScreen) {
        // Find the last occurrence of the screen in the path to pop back to the most recent instance.
        // Use AnyHashable for proper Equatable comparison (hashValue alone risks collisions).
        let target = AnyHashable(screen)
        if let index = path.lastIndex(where: { AnyHashable($0.base) == target }) {
             // Keep everything up to (and including) the target index.
             let newPath = Array(path.prefix(through: index))

             if newPath.count < path.count {
                 path = newPath
             }
        } else if let root = root, AnyHashable(root) == target {
             path.removeAll()
        } else {
            logger.warning("dismissTo(\(String(describing: screen))) failed — screen not found in stack.")
        }
    }
}
