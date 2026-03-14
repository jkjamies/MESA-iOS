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

/// Records events for assertion, usable as an `onEvent` closure.
///
/// Usage:
/// ```swift
/// let sink = TestEventSink<MyEvent>()
/// sink(.increment)
/// sink.events == [.increment]
/// ```
@MainActor
public final class TestEventSink<E: TrapezioEvent> {
    public private(set) var events: [E] = []

    /// The most recently recorded event.
    public var last: E? { events.last }

    /// The number of recorded events.
    public var count: Int { events.count }

    public init() {}

    /// Call as a function to record an event.
    public func callAsFunction(_ event: E) {
        events.append(event)
    }

    /// Clears all recorded events.
    public func clear() {
        events.removeAll()
    }
}
