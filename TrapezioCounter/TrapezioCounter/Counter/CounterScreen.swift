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

import Trapezio

/// The "Parcelable" ID.
/// In a full system, this would be passed around by the Navigator.
struct CounterScreen: TrapezioScreen {
    let initialValue: Int
}

/// The Model.
struct CounterState: TrapezioState {
    var count: Int
    var isSaving: Bool = false
}

/// The Actions.
enum CounterEvent: TrapezioEvent {
    case increment
    case decrement
    case divideByTwo // example of usecase
    case goToSummary
    case requestHelp
}
