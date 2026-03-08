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
@testable import Trapezio

struct FakeScreen: TrapezioScreen {}

struct FakeState: TrapezioState {
    var count: Int = 0
    var label: String = ""
}

enum FakeEvent: TrapezioEvent {
    case increment
    case decrement
    case setLabel(String)
}

@MainActor
final class FakeStore: TrapezioStore<FakeScreen, FakeState, FakeEvent> {
    var handledEvents: [FakeEvent] = []

    override func handle(event: FakeEvent) {
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

enum FakeInteropEvent: TrapezioInteropEvent {
    case didTap
}
