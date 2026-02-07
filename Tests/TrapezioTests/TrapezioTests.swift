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
@testable import Trapezio

// MARK: - Test Doubles

struct TestScreen: TrapezioScreen {}

struct TestState: TrapezioState {
    var count: Int = 0
    var label: String = ""
}

enum TestEvent: TrapezioEvent {
    case increment
    case decrement
    case setLabel(String)
}

@MainActor
final class TestStore: TrapezioStore<TestScreen, TestState, TestEvent> {
    var handledEvents: [TestEvent] = []

    override func handle(event: TestEvent) {
        handledEvents.append(event)
        switch event {
        case .increment:
            update { $0.count += 1 }
        case .decrement:
            update { $0.count -= 1 }
        case .setLabel(let text):
            update { $0.label = text }
        }
    }
}

// MARK: - TrapezioStore Tests

@Suite("TrapezioStore")
struct TrapezioStoreTests {

    @Test("initializes with screen and state")
    @MainActor func initialization() {
        let screen = TestScreen()
        let store = TestStore(screen: screen, initialState: TestState(count: 5))

        #expect(store.state.count == 5)
        #expect(store.screen == screen)
    }

    @Test("update mutates state via copy-on-write")
    @MainActor func updateMutatesState() {
        let store = TestStore(screen: TestScreen(), initialState: TestState())

        store.update { $0.count = 42 }

        #expect(store.state.count == 42)
    }

    @Test("update skips publish when state is unchanged")
    @MainActor func updateSkipsWhenEqual() {
        let store = TestStore(screen: TestScreen(), initialState: TestState(count: 1))

        // Mutate to the same value — state reference should remain unchanged semantically
        store.update { $0.count = 1 }

        #expect(store.state.count == 1)
    }

    @Test("handle(event:) dispatches to override")
    @MainActor func handleEvent() {
        let store = TestStore(screen: TestScreen(), initialState: TestState())

        store.handle(event: .increment)
        store.handle(event: .increment)
        store.handle(event: .decrement)

        #expect(store.state.count == 1)
        #expect(store.handledEvents.count == 3)
    }

    @Test("multiple update fields are independent")
    @MainActor func independentFields() {
        let store = TestStore(screen: TestScreen(), initialState: TestState())

        store.handle(event: .increment)
        store.handle(event: .setLabel("hello"))

        #expect(store.state.count == 1)
        #expect(store.state.label == "hello")
    }

    @Test("conforms to Identifiable")
    @MainActor func identifiable() {
        let store1 = TestStore(screen: TestScreen(), initialState: TestState())
        let store2 = TestStore(screen: TestScreen(), initialState: TestState())

        #expect(store1.id != store2.id)
    }
}

// MARK: - TrapezioMessage Tests

@Suite("TrapezioMessage")
struct TrapezioMessageTests {

    @Test("message equality is based on id")
    func equality() {
        let id = UUID()
        let a = TrapezioMessage(message: "hello", id: id)
        let b = TrapezioMessage(message: "hello", id: id)
        let c = TrapezioMessage(message: "hello")

        #expect(a == b)
        #expect(a != c)
    }
}

// MARK: - TrapezioMessageManager Tests

@Suite("TrapezioMessageManager")
struct TrapezioMessageManagerTests {

    @Test("emit adds message to queue")
    @MainActor func emit() {
        let manager = TrapezioMessageManager()
        let msg = TrapezioMessage(message: "test")

        manager.emit(msg)

        #expect(manager.messages.count == 1)
        #expect(manager.message == msg)
    }

    @Test("clearMessage removes specific message")
    @MainActor func clearMessage() {
        let manager = TrapezioMessageManager()
        let msg1 = TrapezioMessage(message: "first")
        let msg2 = TrapezioMessage(message: "second")

        manager.emit(msg1)
        manager.emit(msg2)
        manager.clearMessage(id: msg1.id)

        #expect(manager.messages.count == 1)
        #expect(manager.message == msg2)
    }

    @Test("clearAll empties the queue")
    @MainActor func clearAll() {
        let manager = TrapezioMessageManager()

        manager.emit(TrapezioMessage(message: "a"))
        manager.emit(TrapezioMessage(message: "b"))
        manager.clearAll()

        #expect(manager.messages.isEmpty)
        #expect(manager.message == nil)
    }

    @Test("message returns first in queue")
    @MainActor func messageReturnsFirst() {
        let manager = TrapezioMessageManager()
        let first = TrapezioMessage(message: "first")

        manager.emit(first)
        manager.emit(TrapezioMessage(message: "second"))

        #expect(manager.message == first)
    }
}

// MARK: - ClosureTrapezioInterop Tests

@Suite("ClosureTrapezioInterop")
struct ClosureTrapezioInteropTests {

    enum TestInteropEvent: TrapezioInteropEvent {
        case didTap
    }

    @Test("send delegates to closure")
    func sendDelegatesToClosure() {
        var received: TrapezioInteropEvent?
        let interop = ClosureTrapezioInterop { event in
            received = event
        }

        interop.send(TestInteropEvent.didTap)

        #expect(received is TestInteropEvent)
    }
}
