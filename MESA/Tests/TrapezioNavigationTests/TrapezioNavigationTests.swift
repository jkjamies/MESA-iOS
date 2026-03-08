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

import Testing
@testable import Trapezio
@testable import TrapezioNavigation

// MARK: - TrapezioStackNavigator Tests

@Suite("TrapezioStackNavigator")
struct TrapezioStackNavigatorTests {

    @Test("goTo appends screen to path")
    @MainActor func goTo() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)

        nav.goTo(FakeScreenB())

        #expect(nav.path.count == 1)
    }

    @Test("goTo multiple screens builds stack")
    @MainActor func goToMultiple() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)

        nav.goTo(FakeScreenB())
        nav.goTo(FakeScreenC(id: 1))
        nav.goTo(FakeScreenC(id: 2))

        #expect(nav.path.count == 3)
    }

    @Test("dismiss pops last screen")
    @MainActor func dismiss() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)
        nav.goTo(FakeScreenB())
        nav.goTo(FakeScreenC(id: 0))

        nav.dismiss()

        #expect(nav.path.count == 1)
    }

    @Test("dismiss on empty path is no-op")
    @MainActor func dismissEmpty() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)

        nav.dismiss()

        #expect(nav.path.isEmpty)
    }

    @Test("dismissToRoot clears entire path")
    @MainActor func dismissToRoot() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)
        nav.goTo(FakeScreenB())
        nav.goTo(FakeScreenC(id: 0))

        nav.dismissToRoot()

        #expect(nav.path.isEmpty)
    }

    @Test("dismissTo pops back to matching screen in path")
    @MainActor func dismissToScreen() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)
        nav.goTo(FakeScreenB())
        nav.goTo(FakeScreenC(id: 1))
        nav.goTo(FakeScreenC(id: 2))

        nav.dismissTo(FakeScreenB())

        #expect(nav.path.count == 1)
    }

    @Test("dismissTo root screen clears path")
    @MainActor func dismissToRootScreen() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)
        nav.goTo(FakeScreenB())
        nav.goTo(FakeScreenC(id: 0))

        nav.dismissTo(FakeScreenA())

        #expect(nav.path.isEmpty)
    }

    @Test("dismissTo non-existent screen is no-op")
    @MainActor func dismissToNonExistent() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)
        nav.goTo(FakeScreenB())

        nav.dismissTo(FakeScreenC(id: 0))

        #expect(nav.path.count == 1)
    }

    @Test("dismissTo finds last occurrence when duplicates exist")
    @MainActor func dismissToLastOccurrence() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)
        nav.goTo(FakeScreenB())       // index 0
        nav.goTo(FakeScreenC(id: 1))  // index 1
        nav.goTo(FakeScreenB())       // index 2
        nav.goTo(FakeScreenC(id: 2))  // index 3

        nav.dismissTo(FakeScreenB())

        // Should keep up to the LAST ScreenB (index 2), so 3 items in path
        #expect(nav.path.count == 3)
    }

    @Test("dismissTo uses Equatable not just hashValue")
    @MainActor func dismissToUsesEquatable() {
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: nil)
        nav.goTo(FakeScreenC(id: 1))
        nav.goTo(FakeScreenC(id: 2))
        nav.goTo(FakeScreenB())

        // Should find FakeScreenC(id: 1), not FakeScreenC(id: 2)
        nav.dismissTo(FakeScreenC(id: 1))

        #expect(nav.path.count == 1)
    }

    @Test("root is preserved after navigation")
    @MainActor func rootPreserved() {
        let root = FakeScreenA()
        let nav = TrapezioStackNavigator(root: root, onInterop: nil)
        nav.goTo(FakeScreenB())
        nav.dismissToRoot()

        #expect(nav.root != nil)
    }

    @Test("interop handler receives events")
    @MainActor func interopHandler() {
        enum TestEvent: TrapezioInteropEvent { case test }
        var received = false
        let nav = TrapezioStackNavigator(root: FakeScreenA(), onInterop: { _ in
            received = true
        })

        nav.interop.send(TestEvent.test)

        #expect(received)
    }
}
