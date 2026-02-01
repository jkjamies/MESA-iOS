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

/// Hoists navigation and coordination logic out of the feature.
@MainActor
public protocol TrapezioNavigator: AnyObject {

    // MARK: - Navigation

    /// Requests navigation to a strongly-typed TrapezioScreen.
    func goTo(_ screen: any TrapezioScreen)

    // MARK: - Dismissal

    /// Dismisses the current active feature.
    func dismiss()

    /// Pops to the root of the current navigation stack.
    func dismissToRoot()

    /// Requests dismissal back to a specific strongly-typed TrapezioScreen.
    func dismissTo(_ screen: any TrapezioScreen)
}
