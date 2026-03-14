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

/// Sealed hierarchy recording all navigator actions for assertion in tests.
///
/// `@unchecked Sendable` because `AnyHashable` associated values wrap
/// `TrapezioScreen` conformers, which are `Hashable & Codable` value types.
public enum NavigationEvent: Equatable, @unchecked Sendable {
    case navigate(screen: AnyHashable)
    case dismiss
    case dismissToRoot
    case dismissTo(screen: AnyHashable)
    case popWithResult(key: String)

    /// Helper to extract the screen from a `.navigate` event.
    public var navigatedScreen: AnyHashable? {
        if case .navigate(let screen) = self { return screen }
        return nil
    }
}
