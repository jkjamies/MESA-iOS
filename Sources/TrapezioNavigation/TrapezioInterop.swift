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

/// Marker protocol for all external navigation/interop events.
/// Consumers should define their own enums conforming to this protocol.
public protocol TrapezioInteropEvent {}

/// Handles legacy or external navigation requests that fall outside the
/// pure Trapezio screen system (e.g., deep links, UIKit bridges).
public protocol TrapezioInterop {
    /// Sends a type-safe interop event to the host.
    func send(_ event: any TrapezioInteropEvent)
}

/// A concrete implementation of TrapezioInterop that delegates to a closure.
public struct ClosureTrapezioInterop: TrapezioInterop {
    private let onEvent: (TrapezioInteropEvent) -> Void

    public init(onEvent: @escaping (TrapezioInteropEvent) -> Void) {
        self.onEvent = onEvent
    }

    public func send(_ event: any TrapezioInteropEvent) {
        onEvent(event)
    }
}
