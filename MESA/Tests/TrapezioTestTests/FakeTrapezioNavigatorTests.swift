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
import TrapezioNavigation
@testable import TrapezioTest

private struct TestScreen: TrapezioScreen {
    let name: String
}

private struct TestResult: TrapezioNavigationResult, Equatable {
    let value: String
}

@Suite("FakeTrapezioNavigator")
struct FakeTrapezioNavigatorTests {

    @Test("goTo records navigate event")
    @MainActor func goToRecords() {
        let nav = FakeTrapezioNavigator()

        nav.goTo(TestScreen(name: "A"))

        #expect(nav.events.count == 1)
        #expect(nav.events.first == .navigate(screen: AnyHashable(TestScreen(name: "A"))))
    }

    @Test("navigatedScreens returns only navigate screens")
    @MainActor func navigatedScreens() {
        let nav = FakeTrapezioNavigator()

        nav.goTo(TestScreen(name: "A"))
        nav.dismiss()
        nav.goTo(TestScreen(name: "B"))

        #expect(nav.navigatedScreens.count == 2)
    }

    @Test("dismiss records dismiss event")
    @MainActor func dismissRecords() {
        let nav = FakeTrapezioNavigator()

        nav.dismiss()

        #expect(nav.events == [.dismiss])
        #expect(nav.dismissCount == 1)
    }

    @Test("dismissToRoot records event")
    @MainActor func dismissToRootRecords() {
        let nav = FakeTrapezioNavigator()

        nav.dismissToRoot()

        #expect(nav.events == [.dismissToRoot])
    }

    @Test("dismissTo records event")
    @MainActor func dismissToRecords() {
        let nav = FakeTrapezioNavigator()

        nav.dismissTo(TestScreen(name: "A"))

        #expect(nav.events.count == 1)
    }

    @Test("popWithResult stores result and records event")
    @MainActor func popWithResultRecords() {
        let nav = FakeTrapezioNavigator()

        nav.popWithResult(key: "k", result: TestResult(value: "v"))

        #expect(nav.events == [.popWithResult(key: "k")])
        #expect(nav.dismissCount == 1)
    }

    @Test("consumeResult returns stored result")
    @MainActor func consumeResult() {
        let nav = FakeTrapezioNavigator()
        nav.popWithResult(key: "k", result: TestResult(value: "v"))

        let result = nav.consumeResult(forKey: "k", as: TestResult.self)

        #expect(result == TestResult(value: "v"))
    }

    @Test("consumeResult returns nil on second call")
    @MainActor func consumeResultSingleConsumption() {
        let nav = FakeTrapezioNavigator()
        nav.popWithResult(key: "k", result: TestResult(value: "v"))

        _ = nav.consumeResult(forKey: "k")
        let second = nav.consumeResult(forKey: "k")

        #expect(second == nil)
    }

    @Test("consumeResult with wrong type returns nil and preserves result")
    @MainActor func consumeResultTypeMismatchPreserves() {
        let nav = FakeTrapezioNavigator()
        nav.popWithResult(key: "k", result: TestResult(value: "v"))

        struct OtherResult: TrapezioNavigationResult { let n: Int }
        let wrong = nav.consumeResult(forKey: "k", as: OtherResult.self)

        #expect(wrong == nil)
        // Result should still be available with the correct type
        let correct = nav.consumeResult(forKey: "k", as: TestResult.self)
        #expect(correct == TestResult(value: "v"))
    }

    @Test("eventStream yields navigation events")
    @MainActor func eventStreamYieldsEvents() async {
        let nav = FakeTrapezioNavigator()
        // Access the lazy stream to initialize the continuation
        let stream = nav.eventStream

        nav.goTo(TestScreen(name: "A"))
        nav.dismiss()

        var collected: [NavigationEvent] = []
        for await event in stream {
            collected.append(event)
            if collected.count == 2 { break }
        }

        #expect(collected == [
            .navigate(screen: AnyHashable(TestScreen(name: "A"))),
            .dismiss
        ])
    }

    @Test("clearResults removes all results without clearing events")
    @MainActor func clearResults() {
        let nav = FakeTrapezioNavigator()
        nav.popWithResult(key: "k", result: TestResult(value: "v"))

        nav.clearResults()

        #expect(nav.consumeResult(forKey: "k") == nil)
        #expect(!nav.events.isEmpty)
    }

    @Test("reset clears all state")
    @MainActor func reset() {
        let nav = FakeTrapezioNavigator()
        nav.goTo(TestScreen(name: "A"))
        nav.popWithResult(key: "k", result: TestResult(value: "v"))

        nav.reset()

        #expect(nav.events.isEmpty)
        #expect(nav.results.isEmpty)
    }
}
