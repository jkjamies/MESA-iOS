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

// MARK: - Test Doubles

struct ScreenA: TrapezioScreen {}
struct ScreenB: TrapezioScreen {}
struct ScreenC: TrapezioScreen { var id: Int = 0 }

// MARK: - TrapezioStackNavigator Tests

@Suite("TrapezioStackNavigator")
struct TrapezioStackNavigatorTests {

    @Test("goTo appends screen to path")
    @MainActor func goTo() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)

        nav.goTo(ScreenB())

        #expect(nav.path.count == 1)
    }

    @Test("goTo multiple screens builds stack")
    @MainActor func goToMultiple() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)

        nav.goTo(ScreenB())
        nav.goTo(ScreenC(id: 1))
        nav.goTo(ScreenC(id: 2))

        #expect(nav.path.count == 3)
    }

    @Test("dismiss pops last screen")
    @MainActor func dismiss() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)
        nav.goTo(ScreenB())
        nav.goTo(ScreenC())

        nav.dismiss()

        #expect(nav.path.count == 1)
    }

    @Test("dismiss on empty path is no-op")
    @MainActor func dismissEmpty() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)

        nav.dismiss()

        #expect(nav.path.isEmpty)
    }

    @Test("dismissToRoot clears entire path")
    @MainActor func dismissToRoot() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)
        nav.goTo(ScreenB())
        nav.goTo(ScreenC())

        nav.dismissToRoot()

        #expect(nav.path.isEmpty)
    }

    @Test("dismissTo pops back to matching screen in path")
    @MainActor func dismissToScreen() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)
        nav.goTo(ScreenB())
        nav.goTo(ScreenC(id: 1))
        nav.goTo(ScreenC(id: 2))

        nav.dismissTo(ScreenB())

        #expect(nav.path.count == 1)
    }

    @Test("dismissTo root screen clears path")
    @MainActor func dismissToRootScreen() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)
        nav.goTo(ScreenB())
        nav.goTo(ScreenC())

        nav.dismissTo(ScreenA())

        #expect(nav.path.isEmpty)
    }

    @Test("dismissTo non-existent screen is no-op")
    @MainActor func dismissToNonExistent() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)
        nav.goTo(ScreenB())

        nav.dismissTo(ScreenC())

        #expect(nav.path.count == 1)
    }

    @Test("dismissTo finds last occurrence when duplicates exist")
    @MainActor func dismissToLastOccurrence() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)
        nav.goTo(ScreenB())       // index 0
        nav.goTo(ScreenC(id: 1))  // index 1
        nav.goTo(ScreenB())       // index 2
        nav.goTo(ScreenC(id: 2))  // index 3

        nav.dismissTo(ScreenB())

        // Should keep up to the LAST ScreenB (index 2), so 3 items in path
        #expect(nav.path.count == 3)
    }

    @Test("dismissTo uses Equatable not just hashValue")
    @MainActor func dismissToUsesEquatable() {
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: nil)
        nav.goTo(ScreenC(id: 1))
        nav.goTo(ScreenC(id: 2))
        nav.goTo(ScreenB())

        // Should find ScreenC(id: 1), not ScreenC(id: 2)
        nav.dismissTo(ScreenC(id: 1))

        #expect(nav.path.count == 1)
    }

    @Test("root is preserved after navigation")
    @MainActor func rootPreserved() {
        let root = ScreenA()
        let nav = TrapezioStackNavigator(root: root, onInterop: nil)
        nav.goTo(ScreenB())
        nav.dismissToRoot()

        #expect(nav.root != nil)
    }

    @Test("interop handler receives events")
    @MainActor func interopHandler() {
        enum TestEvent: TrapezioInteropEvent { case test }
        var received = false
        let nav = TrapezioStackNavigator(root: ScreenA(), onInterop: { _ in
            received = true
        })

        nav.interop.send(TestEvent.test)

        #expect(received)
    }
}
