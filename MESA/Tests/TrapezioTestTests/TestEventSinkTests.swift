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
import Testing
import Trapezio
@testable import TrapezioTest

private enum TestEvent: TrapezioEvent, Equatable {
    case increment
    case decrement
    case custom(String)
}

@Suite("TestEventSink")
struct TestEventSinkTests {

    @Test("records events via callAsFunction")
    @MainActor func recordsEvents() {
        let sink = TestEventSink<TestEvent>()

        sink(.increment)
        sink(.decrement)
        sink(.increment)

        #expect(sink.events == [.increment, .decrement, .increment])
    }

    @Test("last returns most recent event")
    @MainActor func lastEvent() {
        let sink = TestEventSink<TestEvent>()

        sink(.increment)
        sink(.decrement)

        #expect(sink.last == .decrement)
    }

    @Test("count returns number of events")
    @MainActor func count() {
        let sink = TestEventSink<TestEvent>()

        sink(.increment)
        sink(.increment)

        #expect(sink.count == 2)
    }

    @Test("last returns nil when empty")
    @MainActor func lastEmpty() {
        let sink = TestEventSink<TestEvent>()

        #expect(sink.last == nil)
        #expect(sink.count == 0)
    }

    @Test("clear removes all events")
    @MainActor func clear() {
        let sink = TestEventSink<TestEvent>()
        sink(.increment)
        sink(.decrement)

        sink.clear()

        #expect(sink.events.isEmpty)
        #expect(sink.count == 0)
    }
}
